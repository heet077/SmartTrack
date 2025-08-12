import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../controllers/student_controller.dart';

class StudentAttendanceHistoryController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxList courses = [].obs;
  final RxInt totalClasses = 0.obs;
  final RxInt totalPresent = 0.obs;
  final RxInt totalAbsent = 0.obs;
  final RxDouble attendancePercentage = 0.0.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Delay loading to ensure build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAttendanceData();
    });
  }

  Future<void> loadAttendanceData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get current user's email from StudentController
      final studentController = Get.find<StudentController>();
      final student = studentController.currentStudent.value;
      
      if (student == null) {
        error.value = 'Student data not found';
        return;
      }

      // Get enrolled courses
      final enrolledCourses = await _supabase
          .from('courses')
          .select('''
            id,
            code,
            name
          ''')
          .eq('program_id', student.programId);

      debugPrint('Found ${enrolledCourses.length} enrolled courses');

      // Process each course to get attendance statistics
      final processedCourses = await Future.wait(
        enrolledCourses.map((course) async {
          // Get all lecture sessions for this course
          final lectureSessions = await _supabase
              .from('lecture_sessions')
              .select()
              .eq('course_id', course['id'])
              .order('date', ascending: false);

          debugPrint('Found ${lectureSessions.length} lecture sessions for course ${course['code']}');

          // Get attendance records for these sessions
          final attendanceRecords = await _supabase
              .from('attendance_records')
              .select()
              .eq('student_id', student.id)
              .eq('course_id', course['id'])
              .eq('present', true);

          final totalClasses = lectureSessions.length;
          final present = attendanceRecords.length;
          final absent = totalClasses - present;
          final percentage = totalClasses > 0 ? (present / totalClasses) * 100 : 0.0;

          // Get recent attendance (last 5 sessions)
          final recentAttendance = lectureSessions.take(5).map((session) {
            final attended = attendanceRecords.any((record) => 
              record['session_id'] == session['id']
            );
            return {
              'date': session['date'],
              'attended': attended,
              'status': attended ? 'present' : 'absent',
            };
          }).toList();

          return {
            ...course,
            'total_classes': totalClasses,
            'present': present,
            'absent': absent,
            'attendance_percentage': percentage,
            'recent_attendance': recentAttendance,
          };
        }),
      );

      // Calculate overall statistics
      int totalClassesAll = 0;
      int totalPresentAll = 0;
      
      for (final course in processedCourses) {
        totalClassesAll += course['total_classes'] as int;
        totalPresentAll += course['present'] as int;
      }
      
      totalClasses.value = totalClassesAll;
      totalPresent.value = totalPresentAll;
      totalAbsent.value = totalClassesAll - totalPresentAll;
      attendancePercentage.value = totalClassesAll > 0 
          ? (totalPresentAll / totalClassesAll) * 100 
          : 0.0;

      courses.value = processedCourses;

    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      error.value = 'Failed to load attendance data: $e';
      
      courses.clear();
      totalClasses.value = 0;
      totalPresent.value = 0;
      totalAbsent.value = 0;
      attendancePercentage.value = 0.0;
    } finally {
      isLoading.value = false;
    }
  }
} 