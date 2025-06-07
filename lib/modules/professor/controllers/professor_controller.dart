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
  
  // QR code and timer related variables
  final RxInt remainingSeconds = 0.obs;
  final RxBool isQrExpired = false.obs;
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
      }
    });
  }

  void generateNewQrCode() {
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    debugPrint('ProfessorController: Generating new QR code with ${remainingSeconds.value} seconds duration');
    isQrExpired.value = false;
    startQrSession();
  }

  void stopQrSession() {
    debugPrint('ProfessorController: Stopping QR session');
    countdownTimer?.cancel();
    remainingSeconds.value = _adminSettings.qrCodeDuration.value;
    isQrExpired.value = false;
  }

  @override
  void onClose() {
    countdownTimer?.cancel();
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

      // Fetch professor data
      debugPrint('Fetching professor data for email: ${currentUser.email}');
      final professorData = await _supabase
          .from('instructors')
          .select()
          .eq('email', currentUser.email)
          .single();
      
      debugPrint('Raw professor data from database: $professorData');
      
      if (professorData == null) {
        debugPrint('No professor data found in database');
        throw Exception('Professor not found');
      }

      currentProfessor.value = Professor.fromJson(professorData);
      debugPrint('Professor model created: ${currentProfessor.value?.name}');

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
          .eq('instructor_id', currentProfessor.value!.id);

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

  Future<List<Map<String, dynamic>>> getUpcomingLectures() async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday;
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final response = await _supabase
          .from('course_assignments')
          .select('''
            *,
            course:courses (
              id, code, name
            )
          ''')
          .eq('instructor_id', currentProfessor.value?.id)
          .eq('day_of_week', dayOfWeek)
          .gt('start_time', currentTime)
          .order('start_time');

      debugPrint('Upcoming lectures response: $response');
      
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
      debugPrint('Error getting upcoming lectures: $e');
      return [];
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
      await _supabase.auth.signOut();
      currentProfessor.value = null;
      assignedCourses.clear();
      Get.delete<ProfessorController>();  // Delete the controller instance
      Get.delete<professor.AttendanceController>(tag: 'professor');  // Delete attendance controller
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('Error during logout: $e');
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