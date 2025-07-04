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

  // Passcode related variables
  final RxString currentPasscode = ''.obs;
  final RxList<Student> verifiedStudents = <Student>[].obs;

  // Generate a random 6-digit passcode
  String _generatePasscode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Generates a number between 100000 and 999999
  }

  Future<void> startSession(String courseId, String scheduleId) async {
    try {
      isLoading.value = true;
      
      // Get current user's email and instructor ID
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final instructor = await supabase
          .from('instructors')
          .select('id')
          .eq('email', currentUser.email!)
          .single();

      if (instructor == null) throw Exception('Instructor not found');

      // Check if the current date is today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final requestedDate = today; // We'll always use today's date

      // Check for existing sessions today for this course
      final existingSessions = await supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', requestedDate.toIso8601String().split('T')[0])
          .filter('end_time', 'is', null);

      if (existingSessions != null && existingSessions.isNotEmpty) {
        // If there's an existing session, use it instead of creating a new one
        currentSession.value = LectureSession.fromJson(existingSessions[0]);
      } else {
        // Create a new session
        final sessionData = await supabase
            .from('lecture_sessions')
            .insert({
              'course_id': courseId,
              'schedule_id': scheduleId,
              'instructor_id': instructor['id'],
              'date': requestedDate.toIso8601String().split('T')[0],
              'start_time': now.toIso8601String(),
            })
            .select()
            .single();

        currentSession.value = LectureSession.fromJson(sessionData);
      }

      // Start listening for attendance
      _startAttendanceListener();
      
      // Generate initial QR code
      await generateNewQrCode();

      Get.snackbar(
        'Session Started',
        'Have students scan the QR code to mark attendance',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );

    } catch (e) {
      debugPrint('Error starting session: $e');
      Get.snackbar(
        'Error',
        'Failed to start session: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateNewPasscode() async {
    if (currentSession.value == null) return;

    try {
      final newPasscode = _generatePasscode();
      
      await supabase
          .from('lecture_sessions')
          .update({'passcode': newPasscode})
          .eq('id', currentSession.value!.id);

      currentPasscode.value = newPasscode;

      Get.snackbar(
        'New Passcode Generated',
        'Share the new passcode with students: $newPasscode',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );

    } catch (e) {
      print('Error generating new passcode: $e');
      Get.snackbar(
        'Error',
        'Failed to generate new passcode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

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
    currentSession.value = null;
    currentQrCode.value = '';
    currentPasscode.value = '';
    remainingTime.value = 0;
    presentStudents.clear();
    verifiedStudents.clear();
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
          .filter('end_time', 'is', null)
          .single();

      if (existingSession != null) {
        currentSession.value = LectureSession.fromJson(existingSession);
        currentPasscode.value = existingSession['passcode'] ?? '';

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
          // End session when QR code expires
          endSession();
        }
      });

      debugPrint('LectureSessionController: QR code generated and will remain valid for ${qrValidityDuration.value} seconds');
    } catch (e) {
      debugPrint('LectureSessionController: Error generating QR code: $e');
      Get.snackbar('Error', 'Failed to generate QR code: ${e.toString()}');
    }
  }

  void _startAttendanceListener() {
    if (currentSession.value == null) return;

    debugPrint('Starting attendance listener for session: ${currentSession.value!.id}');

    // Cancel existing subscription if any
    _attendanceSubscription?.cancel();

    _attendanceSubscription = supabase
      .from('attendance_records')
      .stream(primaryKey: ['id'])
      .eq('session_id', currentSession.value!.id)
      .listen((List<Map<String, dynamic>> data) async {
        try {
          debugPrint('Received attendance records: ${data.length}');
          final List<Student> scannedStudents = [];
          final List<Student> verified = [];

          for (final record in data) {
            try {
              // Get student details
              final studentData = await supabase
                  .from('students')
                  .select()
                  .eq('id', record['student_id'])
                  .single();

              if (studentData != null) {
                final student = Student(
                  id: studentData['id'],
                  name: studentData['name'],
                  email: studentData['email'],
                  scanTime: record['marked_at'],
                );

                // Add to appropriate list based on verification status
                if (record['finalized'] == true) {
                  verified.add(student);
                } else {
                  scannedStudents.add(student);
                }
              }
            } catch (e) {
              debugPrint('Error processing student record: $e');
            }
          }

          debugPrint('Updating lists - Scanned: ${scannedStudents.length}, Verified: ${verified.length}');
          
          // Update observable lists
          presentStudents.value = scannedStudents;
          verifiedStudents.value = verified;

        } catch (e) {
          debugPrint('Error updating attendance lists: $e');
        }
      });
  }

  Future<void> endSession() async {
    try {
      if (currentSession.value == null) return;
      
      // Cancel timers and cleanup
      _countdownTimer?.cancel();
      _attendanceSubscription?.cancel();
      isQrExpired.value = true;
      
      // Update session in database
      await supabase
          .from('lecture_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'finalized': true,
          })
          .eq('id', currentSession.value!.id);
      
      // Reset controller state
      currentSession.value = null;
      currentQrCode.value = '';
      currentPasscode.value = '';
      remainingTime.value = 0;
      presentStudents.clear();
      verifiedStudents.clear();
      
      Get.snackbar(
        'Session Ended',
        'QR code expired and session has been ended',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate back without deleting controllers
      Get.back();
      
    } catch (e) {
      debugPrint('Error ending session: $e');
      Get.snackbar(
        'Error',
        'Failed to end session',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 