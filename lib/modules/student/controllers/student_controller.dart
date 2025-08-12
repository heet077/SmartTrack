import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../models/student_model.dart';
import '../../admin/models/course_model.dart';
import '../../professor/models/lecture_session.dart';

class StudentController extends GetxController {
  final _supabase = SupabaseService.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Student?> currentStudent = Rx<Student?>(null);
  final Rx<Course?> currentCourse = Rx<Course?>(null);
  final RxList<LectureSession> todayLectures = <LectureSession>[].obs;
  final RxMap<String, double> courseAttendance = <String, double>{}.obs;
  final RxList<Map<String, dynamic>> enrolledCourses = <Map<String, dynamic>>[].obs;
  final String? studentEmail;
  final String? authEmail;

  StudentController({this.studentEmail, this.authEmail});

  @override
  void onInit() {
    super.onInit();
    debugPrint('StudentController onInit called');
    // Delay loading to ensure auth state is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadStudentData();
    });
  }

  Future<void> loadStudentData() async {
    try {
      isLoading.value = true;
      error.value = '';
      hasError.value = false;
      errorMessage.value = '';
      debugPrint('Loading student data...');

      // Use the email from login if available, otherwise try current user
      String? email = studentEmail;
      String? currentAuthEmail = authEmail;
      
      if (currentAuthEmail == null) {
        final user = _supabase.auth.currentUser;
        debugPrint('Current user: ${user?.email}');
        if (user != null && user.email != null) {
          currentAuthEmail = user.email;
        }
      }
      
      if (email == null && currentAuthEmail == null) {
        error.value = 'No authenticated user found';
        hasError.value = true;
        errorMessage.value = 'No authenticated user found';
        Get.offAllNamed('/login');
        return;
      }

      // Create list of emails to check
      final emails = [
        if (email != null) email,
        if (currentAuthEmail != null) currentAuthEmail,
      ].toSet().toList(); // Remove duplicates
      debugPrint('Checking emails: $emails');

      // Try both emails to find the student record
      final studentQuery = await _supabase
          .from('students')
          .select('*, program:programs(*)')
          .filter('email', 'in', emails)
          .maybeSingle();

      if (studentQuery == null) {
        final usedEmails = emails.join(', ');
        debugPrint('No student record found for emails: $usedEmails');
        error.value = 'No student record found';
        hasError.value = true;
        errorMessage.value = 'No student record found for this account';
        // Redirect to login or show appropriate message
        Get.offAllNamed('/login');
        return;
      }

      debugPrint('Student data fetched: $studentQuery');
      currentStudent.value = Student.fromMap(studentQuery);
      debugPrint('Current student: ${currentStudent.value?.name}');

      if (currentStudent.value?.id != null) {
        // Get courses for student's program
        final coursesData = await _supabase
            .from('courses')
            .select()
            .eq('program_id', currentStudent.value!.programId);

        enrolledCourses.value = (coursesData as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        debugPrint('Found ${enrolledCourses.length} enrolled courses');

        // Load today's lectures and attendance stats in parallel
        await Future.wait([
          loadTodayLectures(),
          loadAttendanceStats(),
        ]);
      }

    } catch (e) {
      debugPrint('Error loading student data: $e');
      error.value = 'Failed to load student data';
      hasError.value = true;
      errorMessage.value = 'Failed to load student data: $e';
      Get.offAllNamed('/login');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Course>> loadStudentCourses() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final student = currentStudent.value;
      if (student == null) {
        throw Exception('No student data found');
      }

      // Get courses for the student's program
      final coursesData = await _supabase
          .from('courses')
          .select()
          .eq('program_id', student.programId)
          .order('name');

      return (coursesData as List).map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error loading student courses: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to load courses';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAttendanceStats() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final student = currentStudent.value;
      if (student == null) {
        throw Exception('No student data found');
      }

      // Get course assignments directly through program_id
      final assignmentsData = await _supabase
          .from('instructor_course_assignments')
          .select('''
            *,
            course:courses!inner (
              id, code, name,
              program:programs!inner (
                id
              )
            )
          ''')
          .eq('course.program.id', student.programId);

      // Group assignments by course
      final Map<String, Map<String, dynamic>> courseMap = {};
      for (final assignment in assignmentsData) {
        final course = assignment['course'] as Map<String, dynamic>;
        courseMap[course['id']] = course;
      }

      debugPrint('Processing attendance for ${courseMap.length} courses');

      // Calculate attendance for each course
      final Map<String, double> stats = {};
      for (final course in courseMap.values) {
        final courseId = course['id'];
        final courseCode = course['code'];

        // Get lecture sessions from course assignments
        final sessionsData = await _supabase
            .from('lecture_sessions')
            .select('id')
            .eq('course_id', courseId)
            .count();

        final totalSessions = sessionsData.count;
        debugPrint('Found $totalSessions lecture sessions for course $courseCode');

        // Get attended sessions
        final attendanceData = await _supabase
            .from('attendance_records')
            .select('id')
            .eq('student_id', student.id)
            .eq('course_id', courseId)
            .eq('present', true)
            .count();

        final attendedSessions = attendanceData.count;
        debugPrint('Found $attendedSessions attended sessions for course $courseCode');

        // Calculate percentage
        final percentage = totalSessions > 0
            ? (attendedSessions / totalSessions)
            : 0.0;

        debugPrint('Attendance percentage for $courseCode: ${percentage * 100}%');
        stats[courseCode] = percentage;
      }

      courseAttendance.value = stats;
      debugPrint('Attendance stats updated for ${stats.length} courses');
    } catch (e) {
      debugPrint('Error loading attendance stats: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to load attendance statistics';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTodayLectures() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get today's date
      final now = DateTime.now();
      final dayOfWeek = now.weekday;

      // Get student's courses
      final studentId = _supabase.auth.currentUser?.id;
      if (studentId == null) {
        error.value = 'Not logged in';
        return;
      }

      // Get student's course assignments
      final response = await _supabase
          .from('course_schedule_slots')
          .select('''
            *,
            instructor_course_assignments!inner (
              course:courses!inner (
                id,
                code,
                name,
                program_id
              )
            )
          ''')
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      // Check for rescheduled lectures
      final rescheduledResponse = await _supabase
          .from('lecture_reschedules')
          .select('''
            *,
            course:courses (
              id,
              code,
              name,
              program_id
            )
          ''')
          .gte('expiry_date', now.toIso8601String())
          .eq('rescheduled_datetime::date', now.toIso8601String().split('T')[0]);

      final List<LectureSession> lectures = [];

      // Add regular lectures
      for (final slot in response) {
        final course = slot['instructor_course_assignments']['course'];
        // Only add if course's program_id matches student's programId
        if (course['program_id'] == currentStudent.value!.programId) {
          lectures.add(LectureSession(
            id: slot['id'] ?? '',
            scheduleId: slot['id'] ?? '',
            courseId: course['id'] ?? '',
            instructorId: slot['instructor_course_assignments']['instructor_id'] ?? '',
            courseCode: course['code'] ?? '',
            courseName: course['name'] ?? '',
            classroom: slot['classroom'] ?? '',
            startTime: slot['start_time'] != null ? DateTime.parse('${now.toIso8601String().split('T')[0]}T${slot['start_time']}Z') : DateTime.now(),
            endTime: slot['end_time'] != null ? DateTime.parse('${now.toIso8601String().split('T')[0]}T${slot['end_time']}Z') : DateTime.now(),
          ));
        }
      }

      // Add rescheduled lectures
      for (final reschedule in rescheduledResponse) {
        final course = reschedule['course'];
        // Only add if course's program_id matches student's programId
        if (course['program_id'] == currentStudent.value!.programId) {
          lectures.add(LectureSession(
            id: reschedule['id'] ?? '',
            scheduleId: reschedule['original_schedule_id'] ?? '',
            courseId: course['id'] ?? '',
            instructorId: reschedule['instructor_id'] ?? '',
            courseCode: course['code'] ?? '',
            courseName: course['name'] ?? '',
            classroom: reschedule['classroom'] ?? '',
            startTime: reschedule['rescheduled_datetime'] != null ? DateTime.parse(reschedule['rescheduled_datetime']) : DateTime.now(),
            endTime: reschedule['rescheduled_datetime'] != null ? DateTime.parse(reschedule['rescheduled_datetime']).add(const Duration(minutes: 50)) : DateTime.now().add(const Duration(minutes: 50)),
            isRescheduled: true,
            rescheduleId: reschedule['id'] ?? '',
          ));
        }
      }

      // Sort by start time
      lectures.sort((a, b) => a.startTime.compareTo(b.startTime));
      todayLectures.value = lectures;
    } catch (e) {
      error.value = 'Failed to load lectures';
      print('Error loading lectures: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;

      // First verify current password
      final student = currentStudent.value;
      if (student == null) {
        throw Exception('No student data found');
      }

      final verifyResponse = await _supabase
          .from('students')
          .select()
          .eq('id', student.id)
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
          .from('students')
          .update({'password': newPassword})
          .eq('id', student.id);

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