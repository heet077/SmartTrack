import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class StudentAttendanceHistoryController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxList courses = [].obs;
  final RxInt totalClasses = 0.obs;
  final RxInt totalPresent = 0.obs;
  final RxInt totalAbsent = 0.obs;
  final RxDouble attendancePercentage = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendanceData();
  }

  Future<void> loadAttendanceData() async {
    try {
      isLoading.value = true;

      // Get current user's email
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Get student ID and program
      final studentData = await _supabase
          .from('students')
          .select('id, program_id')
          .eq('email', userEmail)
          .single();

      final studentId = studentData['id'];
      final programId = studentData['program_id'];

      // Get enrolled courses
      final enrolledCourses = await _supabase
          .from('courses')
          .select('''
            id,
            code,
            name
          ''')
          .eq('program_id', programId);

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

          // Get student's attendance records for this course
          final attendanceRecords = await _supabase
              .from('attendance_records')
              .select()
              .eq('student_id', studentId)
              .eq('course_id', course['id']);

          // Create a map of session ID to attendance status for quick lookup
          final attendanceMap = Map.fromEntries(
            attendanceRecords.map((record) => MapEntry(record['session_id'], record))
          );

          final totalClasses = lectureSessions.length;
          var present = 0;

          // Process each lecture session
          final recentAttendance = lectureSessions.take(5).map((session) {
            final attendanceRecord = attendanceMap[session['id']];
            
            // Only count as present if the attendance is finalized and status is present
            final isPresent = attendanceRecord != null && 
                attendanceRecord['finalized'] == true &&
                attendanceRecord['status'] == 'present';
            
            // Determine the status
            String status;
            if (attendanceRecord == null) {
              status = 'absent';
            } else if (attendanceRecord['status'] == 'pending') {
              status = 'pending';
            } else if (attendanceRecord['status'] == 'present' && attendanceRecord['finalized'] == true) {
              status = 'present';
            } else {
              status = 'absent';
            }
            
            if (isPresent) present++;

            return {
              'date': session['date'],
              'status': status,
            };
          }).toList();

          final absent = totalClasses - present;
          final percentage = totalClasses > 0 ? (present / totalClasses) * 100 : 0.0;

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
      Get.snackbar(
        'Error',
        'Failed to load attendance data. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 3),
      );
      
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