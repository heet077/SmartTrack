import 'dart:math';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lecture_session.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../admin/controllers/admin_settings_controller.dart';
import '../../professor/controllers/professor_controller.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final String? scanTime;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.scanTime,
  });
}

class LectureSessionController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final Rx<LectureSession?> currentSession = Rx<LectureSession?>(null);
  final RxString currentQrCode = ''.obs;
  final RxList<Student> presentStudents = <Student>[].obs;
  
  // QR code expiration
  final RxInt remainingTime = 0.obs;
  final RxInt qrValidityDuration = 0.obs;
  final RxBool isQrExpired = false.obs;
  Timer? _countdownTimer;
  StreamSubscription? _attendanceSubscription;
  late final AdminSettingsController _adminSettings;

  @override
  void onInit() {
    super.onInit();
    debugPrint('LectureSessionController: onInit called');
    _adminSettings = Get.find<AdminSettingsController>();
    debugPrint('LectureSessionController: Found AdminSettingsController');
    // Initialize QR validity duration from admin settings
    qrValidityDuration.value = _adminSettings.qrCodeDuration.value;
    debugPrint('LectureSessionController: Initial QR duration set to ${qrValidityDuration.value} seconds');
    
    // Listen for changes in admin settings
    ever(_adminSettings.qrCodeDuration, (int duration) {
      debugPrint('LectureSessionController: Admin settings changed, updating duration to $duration seconds');
      qrValidityDuration.value = duration;
      // Only update remaining time if a session is active and not expired
      if (currentSession.value != null && !isQrExpired.value) {
        remainingTime.value = duration;
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _attendanceSubscription?.cancel();
    super.onClose();
  }

  Future<void> initSession(String courseId, String scheduleId) async {
    try {
      isLoading.value = true;

      // Check for existing active session
      final existingSession = await supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('schedule_id', scheduleId)
          .is_('end_time', null)
          .single();

      if (existingSession != null) {
        currentSession.value = LectureSession.fromJson(existingSession);

        // Start listening for attendance
        _startAttendanceListener();
        
        // Generate initial QR code
        await generateNewQrCode();
      }
    } catch (e) {
      print('Error initializing session: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startSession(String courseId, String scheduleId) async {
    try {
      isLoading.value = true;
      debugPrint('LectureSessionController: Starting new session');

      // First check if there's already an active session
      final existingSession = await supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('schedule_id', scheduleId)
          .is_('end_time', null)
          .maybeSingle();

      if (existingSession != null) {
        currentSession.value = LectureSession.fromJson(existingSession);
        await generateNewQrCode();
        return;
      }

      // Get the current user's ID (instructor ID)
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get instructor ID from instructors table
      final instructor = await supabase
          .from('instructors')
          .select()
          .eq('email', currentUser.email)
          .single();

      // Get current date and time
      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day);

      // Create new session
      final session = await supabase.from('lecture_sessions').insert({
        'course_id': courseId,
        'schedule_id': scheduleId,
        'instructor_id': instructor['id'],
        'date': currentDate.toIso8601String(),
        'start_time': now.toIso8601String(),
        'finalized': false,
      }).select().single();

      currentSession.value = LectureSession.fromJson(session);
      
      // Generate initial QR code
      await generateNewQrCode();
      
    } catch (e) {
      debugPrint('LectureSessionController: Error starting session: $e');
      Get.snackbar(
        'Error',
        'Failed to start session. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateNewQrCode() async {
    if (currentSession.value == null) return;

    try {
      debugPrint('LectureSessionController: Generating new QR code with duration: ${qrValidityDuration.value} seconds');
      
      // Generate QR data with validity information
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final validUntil = now.add(Duration(seconds: qrValidityDuration.value)).millisecondsSinceEpoch;
      final sessionId = currentSession.value!.id;
      
      final qrData = {
        'session_id': sessionId,
        'timestamp': timestamp,
        'valid_until': validUntil
      };
      
      final encodedQrData = base64Encode(utf8.encode(json.encode(qrData)));
      
      // Set the QR code without updating the database
      currentQrCode.value = encodedQrData;
      isQrExpired.value = false;
      remainingTime.value = qrValidityDuration.value;
      
      // Cancel any existing timer
      _countdownTimer?.cancel();
      
      // Start a new countdown timer
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.value > 0) {
          remainingTime.value--;
        } else {
          debugPrint('LectureSessionController: QR code expired');
          isQrExpired.value = true;
          timer.cancel();
        }
      });

      debugPrint('LectureSessionController: QR code generated and will remain valid for ${qrValidityDuration.value} seconds');
    } catch (e) {
      debugPrint('LectureSessionController: Error generating QR code: $e');
      Get.snackbar('Error', 'Failed to generate QR code: ${e.toString()}');
    }
  }

  Future<void> endSession() async {
    try {
      if (currentSession.value == null) return;
      
      _countdownTimer?.cancel();
      isQrExpired.value = true;
      
      await supabase
          .from('lecture_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'finalized': true,
          })
          .eq('id', currentSession.value!.id);
      
      currentSession.value = null;
      currentQrCode.value = '';
      remainingTime.value = 0;
      
      // Reset the selected course ID in the professor controller
      final professorController = Get.find<ProfessorController>();
      professorController.selectedCourseId.value = '';
      professorController.stopQrSession();
      
    } catch (e) {
      debugPrint('LectureSessionController: Error ending session: $e');
      Get.snackbar(
        'Error',
        'Failed to end session',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _startAttendanceListener() {
    if (currentSession.value == null) return;

    _attendanceSubscription = supabase
        .from('attendance_records')
        .stream(primaryKey: ['id'])
        .eq('session_id', currentSession.value!.id)
        .listen((List<Map<String, dynamic>> data) async {
          try {
            final studentIds = data.map((record) => record['student_id']).toList();
            
            if (studentIds.isEmpty) {
              presentStudents.clear();
              return;
            }

            final students = await supabase
                .from('students')
                .select()
                .in_('id', studentIds);

            presentStudents.value = students.map((student) {
              final record = data.firstWhere(
                (r) => r['student_id'] == student['id'],
                orElse: () => {'created_at': null},
              );
              
              return Student(
                id: student['id'],
                name: student['name'],
                email: student['email'],
                scanTime: record['created_at'],
              );
            }).toList();
          } catch (e) {
            print('Error updating present students: $e');
          }
        });
  }
} 