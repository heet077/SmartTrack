import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../models/student_model.dart';
import '../../admin/models/course_model.dart';

class StudentController extends GetxController {
  final _supabase = SupabaseService.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Student?> currentStudent = Rx<Student?>(null);
  final Rx<Course?> currentCourse = Rx<Course?>(null);
  final RxList<Map<String, dynamic>> todayLectures = <Map<String, dynamic>>[].obs;
  final RxMap<String, double> courseAttendance = <String, double>{}.obs;
  final RxList<Map<String, dynamic>> enrolledCourses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('StudentController onInit called');
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      isLoading.value = true;
      error.value = '';
      hasError.value = false;
      errorMessage.value = '';
      debugPrint('Loading student data...');

      final user = _supabase.auth.currentUser;
      debugPrint('Current user: ${user?.email}');

      if (user == null || user.email == null) {
        error.value = 'No authenticated user found';
        hasError.value = true;
        errorMessage.value = 'No authenticated user found';
        return;
      }

      // Load student data and courses in parallel
      final studentData = await _supabase
          .from('students')
          .select('*, program:programs(*)')
          .eq('email', user.email as String)
          .single();

      debugPrint('Student data fetched: $studentData');
      currentStudent.value = Student.fromMap(studentData);
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
          _loadTodayLectures(),
          loadAttendanceStats(),
        ]);
      }

    } catch (e) {
      debugPrint('Error loading student data: $e');
      error.value = 'Failed to load student data';
      hasError.value = true;
      errorMessage.value = 'Failed to load student data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Course>> loadStudentCourses() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get student's program ID
      final studentData = await _supabase
          .from('students')
          .select('program_id')
          .eq('email', user.email as String)
          .single();

      // Get courses for the student's program
      final coursesData = await _supabase
          .from('courses')
          .select()
          .eq('program_id', studentData['program_id'])
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

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get student ID
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('email', user.email as String)
          .single();

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
          .eq('course.program.id', currentStudent.value!.programId);

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
            .eq('student_id', studentData['id'])
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

  Future<void> _loadTodayLectures() async {
    try {
      debugPrint('Loading today\'s lectures...');
      if (currentStudent.value?.programId == null) return;

      final now = DateTime.now();
      final dayOfWeek = now.weekday;

      debugPrint('Loading lectures for program ID: ${currentStudent.value?.programId} on day: $dayOfWeek');

      // Get course assignments directly through program_id
      final response = await _supabase
          .from('course_schedule_slots')
          .select('''
            *,
            assignment:instructor_course_assignments!inner (
              id,
              instructor:instructors (
                id, name
              ),
              course:courses!inner (
                id, name, code,
                program:programs!inner (
                  id
                )
              )
            )
          ''')
          .eq('day_of_week', dayOfWeek)
          .eq('assignment.course.program.id', currentStudent.value!.programId)
          .order('start_time');

      // Transform the response into the required format
      final lectures = (response as List).map((schedule) {
        final assignment = schedule['assignment'] as Map<String, dynamic>;
        final course = assignment['course'] as Map<String, dynamic>;
        final instructor = assignment['instructor'] as Map<String, dynamic>;
        
        return {
          'subject': '${course['code']}: ${course['name']}',
          'room': schedule['classroom'] ?? 'TBD',
          'professor': instructor?['name'] ?? 'Not Assigned',
          'time': '${schedule['start_time']} - ${schedule['end_time']}',
        };
      }).toList();

      debugPrint('Lectures fetched: $lectures');
      todayLectures.value = lectures;
      debugPrint('Today\'s lectures processed: ${todayLectures.length}');
    } catch (e) {
      debugPrint('Error loading today\'s lectures: $e');
      // Don't set error state as this is not critical for the dashboard
      todayLectures.value = [];
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

  @override
  void onClose() {
    debugPrint('StudentController onClose called');
    super.onClose();
  }
} 