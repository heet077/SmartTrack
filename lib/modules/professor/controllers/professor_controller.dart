import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professor_model.dart';
import '../controllers/attendance_controller.dart' as professor;
import '../models/assigned_course.dart' as course_model;
import 'dart:async';
import '../../admin/controllers/admin_settings_controller.dart';

class ProfessorController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  final _supabase = Supabase.instance.client;
  final Rx<Professor?> currentProfessor = Rx<Professor?>(null);
  final RxList<course_model.AssignedCourse> assignedCourses = <course_model.AssignedCourse>[].obs;
  final RxString selectedCourseId = ''.obs;
  final RxInt currentIndex = 0.obs;
  
  // Add getters for dayOfWeek and currentTime
  int get dayOfWeek => DateTime.now().weekday;
  String get currentTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
  }
  
  // QR code and timer related variables
  final RxInt remainingSeconds = 0.obs;
  final RxBool isQrExpired = false.obs;
  final RxString currentQrCode = ''.obs;
  final Rx<DateTime> qrExpiryTime = Rx<DateTime>(DateTime.now());
  final Rx<course_model.AssignedCourse?> selectedCourse = Rx<course_model.AssignedCourse?>(null);
  Timer? countdownTimer;
  late final AdminSettingsController _adminSettings;

  @override
  void onInit() {
    super.onInit();
    debugPrint('ProfessorController: onInit called');
    _adminSettings = Get.find<AdminSettingsController>();
    debugPrint('ProfessorController: Found AdminSettingsController');
    // Initialize remaining seconds from admin settings
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    debugPrint('ProfessorController: Initial remaining seconds set to ${remainingSeconds.value}');
    
    // Listen for changes in admin settings
    ever(_adminSettings.qrCodeDuration, (int duration) {
      debugPrint('ProfessorController: Admin settings changed to $duration seconds');
      if (!isQrExpired.value) {
        remainingSeconds.value = duration;
        debugPrint('ProfessorController: Updated remaining seconds to $duration');
      }
    });

    // Listen for changes in selectedCourseId
    ever(selectedCourseId, (String id) {
      if (id.isNotEmpty) {
        try {
          selectedCourse.value = assignedCourses.firstWhere(
            (course) => course.courseId == id,
          );
        } catch (e) {
          selectedCourse.value = null;
        }
      } else {
        selectedCourse.value = null;
      }
    });

    // Check if user is already authenticated
    final session = _supabase.auth.currentSession;
    if (session != null) {
      loadProfessorData();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void startQrSession() {
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    debugPrint('ProfessorController: Starting QR session with ${remainingSeconds.value} seconds');
    isQrExpired.value = false;
    
    // Generate new QR code
    currentQrCode.value = DateTime.now().millisecondsSinceEpoch.toString();
    qrExpiryTime.value = DateTime.now().add(Duration(seconds: remainingSeconds.value));
    
    // Cancel existing timer if any
    countdownTimer?.cancel();
    
    // Start countdown timer
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        debugPrint('ProfessorController: QR session expired');
        timer.cancel();
        isQrExpired.value = true;
        // Clean up state when session expires
        cleanupSession();
      }
    });
  }

  void cleanupSession() {
    debugPrint('ProfessorController: Cleaning up session state');
    countdownTimer?.cancel();
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    isQrExpired.value = false;
    currentQrCode.value = '';
    selectedCourseId.value = '';
  }

  void generateNewQrCode() {
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    debugPrint('ProfessorController: Generating new QR code with ${remainingSeconds.value} seconds duration');
    isQrExpired.value = false;
    currentQrCode.value = DateTime.now().millisecondsSinceEpoch.toString();
    qrExpiryTime.value = DateTime.now().add(Duration(seconds: remainingSeconds.value));
    startQrSession();
  }

  void stopQrSession() {
    debugPrint('ProfessorController: Stopping QR session');
    cleanupSession();
  }

  @override
  void onClose() {
    cleanupSession();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;

      // Clear any existing data
      currentProfessor.value = null;
      assignedCourses.clear();

      // First try to sign in with Supabase auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }

      // After successful auth, check if user exists in instructors table
      final professorData = await _supabase
          .from('instructors')
          .select()
          .eq('email', email)
          .single();

      // Set current professor data
      currentProfessor.value = Professor.fromJson(professorData);

      // Load assigned courses
      await loadProfessorData();

      // Navigate to dashboard
      Get.offAllNamed('/professor/dashboard');

    } catch (e) {
      debugPrint('Login error: $e');
      Get.snackbar(
        'Error',
        'Invalid credentials or not authorized as professor',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Future<void> loadProfessorData() async {
    try {
      isLoading.value = true;
      debugPrint('Starting to load professor data...');

      // Get current user's email
      final currentUser = _supabase.auth.currentUser;
      debugPrint('Current user: ${currentUser?.email}');
      
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        throw Exception('Not authenticated');
      }

      // Clear existing data
      currentProfessor.value = null;
      assignedCourses.clear();

      // First fetch basic professor data
      debugPrint('Fetching professor data for email: ${currentUser.email}');
      final professorData = await _supabase
          .from('instructors')
          .select()
          .eq('email', currentUser.email!)
          .single();
      
      if (professorData == null) {
        debugPrint('No professor data found in database');
        throw Exception('Professor not found');
      }

      debugPrint('Found professor data: $professorData');

      // Create professor object with basic data first
      currentProfessor.value = Professor(
        id: professorData['id'] ?? '',
        name: professorData['name'] ?? '',
        email: professorData['email'] ?? '',
        phone: professorData['phone'],
        program: null,  // Will be updated if program data is found
        role: professorData['role'] ?? 'instructor',
      );

      try {
        // Then try to fetch program information separately
        final programData = await _supabase
            .from('instructor_program_mappings')
            .select('''
              program:programs (
                id,
                name,
                code
              )
            ''')
            .eq('instructor_id', professorData['id'])
            .maybeSingle();

        debugPrint('Program data response: $programData');

        // Update program name if available
        if (programData != null && programData['program'] != null) {
          final programName = programData['program']['name'];
          debugPrint('Found program name: $programName');
          currentProfessor.value = currentProfessor.value!.copyWith(program: programName);
        } else {
          debugPrint('No program data found for instructor');
        }
      } catch (e) {
        debugPrint('Error fetching program data: $e');
        // Continue without program data
      }
      
      // Fetch assigned courses with course details
      debugPrint('Fetching assigned courses for professor ID: ${currentProfessor.value!.id}');
      final assignedCoursesData = await _supabase
          .from('course_assignments')
          .select('''
            *,
            course:courses (
              id, name, code, semester, credits
            )
          ''')
          .eq('instructor_id', currentProfessor.value!.id!)
          .order('day_of_week', ascending: true)
          .order('start_time');

      debugPrint('Raw assigned courses data: $assignedCoursesData');

      assignedCourses.value = (assignedCoursesData as List)
          .map<course_model.AssignedCourse>((json) => course_model.AssignedCourse.fromJson(json))
          .toList();
          
      debugPrint('Number of assigned courses loaded: ${assignedCourses.length}');
      for (var course in assignedCourses) {
        debugPrint('Loaded course: ${course.course.code} - ${course.course.name}');
      }

    } catch (e, stackTrace) {
      debugPrint('Error loading professor data: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load professor data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getTodayLectures() async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday;

      final response = await _supabase
          .from('course_assignments')
          .select('''
            *,
            course:courses (
              id, code, name
            )
          ''')
          .eq('instructor_id', currentProfessor.value?.id ?? '' as Object)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      debugPrint('Today\'s lectures response: $response');
      
      if (response == null) {
        return [];
      }

      return (response as List).map<Map<String, dynamic>>((lecture) {
        final course = lecture['course'] as Map<String, dynamic>;
        return {
          'course': {
            'code': course['code'],
            'name': course['name'],
          },
          'classroom': lecture['classroom'],
          'start_time': lecture['start_time'],
          'end_time': lecture['end_time'],
        };
      }).toList();

    } catch (e) {
      debugPrint('Error getting today\'s lectures: $e');
      return [];
    }
  }

  // Check if a course has a lecture scheduled for today
  Future<bool> hasLectureToday(String courseId) async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      
      final response = await _supabase
          .from('course_assignments')
          .select()
          .eq('course_id', courseId)
          .eq('day_of_week', now.weekday)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime)
          .maybeSingle();

      debugPrint('Checking lecture for course $courseId at $currentTime: ${response != null}');
      debugPrint('Response: $response');

      // If no exact match, check if there's a lecture scheduled for today
      if (response == null) {
        final todayLecture = await _supabase
            .from('course_assignments')
            .select()
            .eq('course_id', courseId)
            .eq('day_of_week', now.weekday)
            .maybeSingle();
            
        return todayLecture != null;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking lecture schedule: $e');
      return false;
    }
  }

  // Check if attendance has already been taken for this course today
  Future<bool> hasAttendanceToday(String courseId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', today)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking today\'s attendance: $e');
      return false;
    }
  }

  Future<Map<String, double>> getCourseAttendanceStats(String courseId) async {
    try {
      final response = await _supabase
          .rpc('calculate_course_attendance', params: {
            'p_course_id': courseId,  // Updated parameter name to match function
          });

      if (response == null) {
        return {'attendance_rate': 0.0};
      }

      return {
        'attendance_rate': (response as num).toDouble(),
      };
    } catch (e) {
      debugPrint('Error getting course attendance stats: $e');
      return {'attendance_rate': 0.0};
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Reset controller state
      currentProfessor.value = null;
      assignedCourses.clear();
      cleanupSession();
      
      // Navigate to login screen first
      await Get.offAllNamed('/login');
      
      // Then delete controllers after navigation is complete
      Get.delete<professor.AttendanceController>(tag: 'professor', force: true);
      Get.delete<ProfessorController>(force: true);
    } catch (e) {
      debugPrint('Error during logout: $e');
      Get.snackbar(
        'Error',
        'Failed to logout properly',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  course_model.AssignedCourse? getSelectedCourse() {
    if (selectedCourseId.value.isEmpty) return null;
    return assignedCourses.firstWhere(
      (course) => course.courseId == selectedCourseId.value,
      orElse: () => null as course_model.AssignedCourse,
    );
  }
} 