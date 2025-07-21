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
      debugPrint('Attempting professor login with email: $email');

      // First check if instructor exists and password matches
      final instructorCheck = await _supabase
          .from('instructors')
          .select()
          .eq('email', email.trim().toLowerCase())
          .eq('password', password.trim())
          .maybeSingle();

      if (instructorCheck == null) {
        Get.snackbar(
          'Error',
          'Invalid credentials',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // If instructor exists and password matches, create Supabase auth session
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Load professor data
        currentProfessor.value = Professor(
          id: instructorCheck['id'],
          name: instructorCheck['name'],
          email: instructorCheck['email'],
        );

        // Navigate to dashboard
        Get.offAllNamed('/professor/dashboard');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      Get.snackbar(
        'Error',
        'Failed to login',
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

  Future<int> getStudentCount(String courseId) async {
    try {
      // Get course details to get program_id and semester
      final courseData = await _supabase
          .from('courses')
          .select('program_id, semester')
          .eq('id', courseId)
          .single();

      if (courseData == null) return 0;

      // Get count of students in the same program and semester
      final studentsCount = await _supabase
          .from('students')
          .select('id')
          .eq('program_id', courseData['program_id'])
          .eq('semester', courseData['semester'])
          .count();

      debugPrint('Student count for course $courseId: ${studentsCount.count}');
      return studentsCount.count;
    } catch (e) {
      debugPrint('Error getting student count: $e');
      return 0;
    }
  }

  // Add this RxMap to store student counts
  final RxMap<String, int> courseStudentCounts = <String, int>{}.obs;

  // Modify loadProfessorData to include student count fetching
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
      courseStudentCounts.clear();

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
      
      // Fetch assigned courses with course details and schedule slots
      debugPrint('Fetching assigned courses for professor ID: ${currentProfessor.value!.id}');
      final assignedCoursesData = await _supabase
          .from('instructor_course_assignments')
          .select('''
            *,
            course:courses (
              id, name, code, semester, credits
            ),
            schedule:course_schedule_slots (
              id, classroom, day_of_week, start_time, end_time
            )
          ''')
          .eq('instructor_id', currentProfessor.value!.id!)
          .order('created_at');

      debugPrint('Raw assigned courses data: $assignedCoursesData');

      // Create a map to store unique courses with their schedules
      final Map<String, course_model.AssignedCourse> uniqueCourses = {};

      for (final assignment in assignedCoursesData) {
        final course = assignment['course'] as Map<String, dynamic>;
        final schedules = assignment['schedule'] as List;
        
        for (final schedule in schedules) {
          final assignedCourse = course_model.AssignedCourse(
            id: schedule['id'],
            instructorId: assignment['instructor_id'],
            courseId: course['id'],
            classroom: schedule['classroom'] ?? '',
            dayOfWeek: schedule['day_of_week'],
            startTime: schedule['start_time'],
            endTime: schedule['end_time'],
            course: course_model.Course.fromJson(course),
          );

          // Use courseId as key to ensure uniqueness
          final key = '${course['id']}_${schedule['day_of_week']}_${schedule['start_time']}';
          uniqueCourses[key] = assignedCourse;

          // Fetch student count for this course if we haven't already
          if (!courseStudentCounts.containsKey(course['id'])) {
            final count = await getStudentCount(course['id']);
            courseStudentCounts[course['id']] = count;
          }
        }
      }

      // Convert map values to list
      assignedCourses.value = uniqueCourses.values.toList();
      debugPrint('Processed ${assignedCourses.length} unique courses');

      if (assignedCoursesData == null || (assignedCoursesData as List).isEmpty) {
        // Try fetching today's lectures directly
        debugPrint('No courses found in regular query, trying today\'s lectures...');
        final now = DateTime.now();
        final todayLectures = await _supabase
            .from('instructor_course_assignments')
            .select('''
              *,
              course:courses (
                id, code, name
              ),
              schedule:course_schedule_slots (
                id, classroom, day_of_week, start_time, end_time
              )
            ''')
            .eq('instructor_id', currentProfessor.value!.id!)
            .eq('schedule.day_of_week', now.weekday);

        debugPrint('Today\'s lectures response: $todayLectures');
        
        if (todayLectures != null && (todayLectures as List).isNotEmpty) {
          assignedCourses.value = (todayLectures as List).expand<course_model.AssignedCourse>((assignment) {
            final scheduleSlots = assignment['schedule'] as List;
            return scheduleSlots.map((slot) => course_model.AssignedCourse(
              id: slot['id'],
              instructorId: assignment['instructor_id'],
              courseId: assignment['course_id'],
              classroom: slot['classroom'] ?? '',
              dayOfWeek: slot['day_of_week'],
              startTime: slot['start_time'],
              endTime: slot['end_time'],
              course: course_model.Course.fromJson(assignment['course']),
            ));
          }).toList();
        }
      } else {
        // Transform the data to match the AssignedCourse model
        assignedCourses.value = (assignedCoursesData as List).expand<course_model.AssignedCourse>((assignment) {
          final scheduleSlots = assignment['schedule'] as List;
          debugPrint('Schedule slots for course ${assignment['course']['code']}: $scheduleSlots');
          
          if (scheduleSlots.isEmpty) {
            debugPrint('Warning: No schedule slots found for course ${assignment['course']['code']}');
            return [];
          }
          
          return scheduleSlots.map((slot) {
            final course = course_model.AssignedCourse(
              id: slot['id'],
              instructorId: assignment['instructor_id'],
              courseId: assignment['course_id'],
              classroom: slot['classroom'] ?? '',
              dayOfWeek: slot['day_of_week'],
              startTime: slot['start_time'],
              endTime: slot['end_time'],
              course: course_model.Course.fromJson(assignment['course']),
            );
            debugPrint('Created AssignedCourse: ${course.course.code} - ${course.dayOfWeek} - ${course.startTime}-${course.endTime}');
            return course;
          });
        }).toList();
      }
          
      debugPrint('Number of assigned courses loaded: ${assignedCourses.length}');
      for (var course in assignedCourses) {
        debugPrint('Loaded course: ${course.course.code} - ${course.course.name} - Day: ${course.dayOfWeek} - Time: ${course.startTime}-${course.endTime}');
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

      // First get instructor's assigned courses
      final assignedCoursesResponse = await _supabase
          .from('instructor_course_assignments')
          .select('''
            *,
            course:courses (
              id, code, name
            ),
            schedule:course_schedule_slots!inner (
              classroom, start_time, end_time
            )
          ''')
          .eq('instructor_id', currentProfessor.value?.id ?? '')
          .eq('schedule.day_of_week', dayOfWeek);

      debugPrint('Today\'s lectures response: $assignedCoursesResponse');
      
      if (assignedCoursesResponse == null) {
        return [];
      }

      return (assignedCoursesResponse as List).map<Map<String, dynamic>>((assignment) {
        final course = assignment['course'] as Map<String, dynamic>;
        final schedule = (assignment['schedule'] as List).first;
        return {
          'course': {
            'code': course['code'],
            'name': course['name'],
          },
          'classroom': schedule['classroom'],
          'start_time': schedule['start_time'],
          'end_time': schedule['end_time'],
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
      debugPrint('Checking lecture for course $courseId on day: ${now.weekday}');
      
      // First get the instructor's assignment for this course
      final assignmentResponse = await _supabase
          .from('instructor_course_assignments')
          .select('id')
          .eq('instructor_id', currentProfessor.value?.id ?? '')
          .eq('course_id', courseId)
          .maybeSingle();

      if (assignmentResponse == null) {
        debugPrint('No assignment found for course $courseId');
        return false;
      }

      final assignmentId = assignmentResponse['id'];
      debugPrint('Found assignment: $assignmentId');

      // Then check if there's a schedule for today
      final scheduleResponse = await _supabase
          .from('course_schedule_slots')
          .select()
          .eq('assignment_id', assignmentId)
          .eq('day_of_week', now.weekday)
          .maybeSingle();

      debugPrint('Schedule response for course $courseId: $scheduleResponse');
      return scheduleResponse != null;
    } catch (e) {
      debugPrint('Error checking lecture schedule: $e');
      return false;
    }
  }

  // Check if attendance has already been taken for this course today
  Future<bool> hasAttendanceToday(String courseId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      debugPrint('Checking attendance for course $courseId on date: $today');
      
      final response = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', today)
          .not('end_time', 'is', null)  // Check if session is ended
          .maybeSingle();

      debugPrint('Attendance check response for course $courseId: $response');
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
      
      // Clear text fields
      emailController.clear();
      passwordController.clear();
      
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

  // Check if a lecture can be started based on current time and schedule
  Future<bool> canStartLecture(String courseId) async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      final currentDayOfWeek = now.weekday;  // 1 = Monday, 7 = Sunday
      debugPrint('Checking lecture for course $courseId at current time: $currentTime, day: $currentDayOfWeek');

      // First get the instructor's assignment for this course
      final assignmentResponse = await _supabase
          .from('instructor_course_assignments')
          .select('id')
          .eq('instructor_id', currentProfessor.value?.id ?? '')
          .eq('course_id', courseId)
          .maybeSingle();

      if (assignmentResponse == null) {
        debugPrint('No assignment found for course $courseId');
        return false;
      }

      final assignmentId = assignmentResponse['id'];
      debugPrint('Found assignment: $assignmentId');

      // Then check schedule slots
      final scheduleResponse = await _supabase
          .from('course_schedule_slots')
          .select()
          .eq('assignment_id', assignmentId)
          .eq('day_of_week', currentDayOfWeek)
          .maybeSingle();

      if (scheduleResponse == null) {
        debugPrint('No schedule found for today');
        return false;
      }

      final startTime = scheduleResponse['start_time'] as String;
      final endTime = scheduleResponse['end_time'] as String;
      final scheduleId = scheduleResponse['id'] as String;

      // Convert times to comparable format (minutes since midnight)
      final currentMinutes = _timeToMinutes(currentTime);
      final startMinutes = _timeToMinutes(startTime) - 15; // 15 minutes buffer before
      final endMinutes = _timeToMinutes(endTime) + 15; // 15 minutes buffer after

      debugPrint('Checking slot $scheduleId: $startTime - $endTime');
      debugPrint('Current minutes: $currentMinutes, Start: $startMinutes, End: $endMinutes');

      if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
        // Check if there's already any lecture session for today with this schedule_id
        final today = DateTime.now().toIso8601String().split('T')[0];
        final lectureSession = await _supabase
            .from('lecture_sessions')
            .select()
            .eq('course_id', courseId)
            .eq('date', today)
            .eq('schedule_id', scheduleId)
            .maybeSingle();

        if (lectureSession != null) {
          debugPrint('Found existing lecture session for schedule $scheduleId');
          return false;
        }

        debugPrint('Found matching time slot $scheduleId for course $courseId');
        return true;
      }

      debugPrint('Current time not within lecture window');
      return false;
    } catch (e) {
      debugPrint('Error checking if lecture can be started: $e');
      return false;
    }
  }

  // Helper method to convert time string to minutes since midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;

      // First verify current password
      final professor = currentProfessor.value;
      if (professor == null) {
        throw Exception('No professor data found');
      }

      final verifyResponse = await _supabase
          .from('instructors')
          .select()
          .eq('id', professor.id)
          .eq('password', currentPassword)
          .maybeSingle();

      if (verifyResponse == null) {
        Get.snackbar(
          'Error',
          'Current password is incorrect',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Update password in database
      await _supabase
          .from('instructors')
          .update({'password': newPassword})
          .eq('id', professor.id);

      // Update Supabase auth password
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Password changed successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error changing password: $e');
      Get.snackbar(
        'Error',
        'Failed to change password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 