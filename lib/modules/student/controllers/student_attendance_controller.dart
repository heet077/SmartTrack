import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class StudentAttendanceController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<CourseAttendance> courseAttendances = <CourseAttendance>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendanceData();
  }

  Future<void> loadAttendanceData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get current student
      final studentId = _supabase.auth.currentUser?.id;
      if (studentId == null) {
        error.value = 'User not authenticated';
        return;
      }

      // Get student's program ID
      final studentData = await _supabase
          .from('students')
          .select('program_id, name')
          .eq('id', studentId)
          .maybeSingle();

      if (studentData == null) {
        error.value = 'Student data not found';
        return;
      }

      final programId = studentData['program_id'];
      if (programId == null) {
        error.value = 'No program assigned to student';
        return;
      }

      // Get all courses for student's program
      final courses = await _supabase
          .from('courses')
          .select('id, name, code')
          .eq('program_id', programId);

      if (courses == null || courses.isEmpty) {
        debugPrint('No courses found for program');
        return;
      }

      // Get attendance for each course
      final List<CourseAttendance> attendances = [];
      for (final course in courses) {
        final attendanceRecords = await _supabase
            .from('attendance_records')
            .select()
            .eq('course_id', course['id'])
            .eq('student_id', studentId);

        final total = attendanceRecords.length;
        final attended = attendanceRecords.where((record) => 
          record['status'] == 'present'
        ).length;

        // Always add the course, even if no attendance records
        final percentage = total > 0 ? attended / total : 0.0;
        attendances.add(CourseAttendance(
          subject: '${course['code']}: ${course['name']}',
          attended: attended,
          total: total,
          percentage: percentage,
          isWarning: percentage < 0.75, // Warning if below 75%
        ));
      }

      courseAttendances.assignAll(attendances);

    } catch (e) {
      error.value = 'Error loading attendance data: $e';
      debugPrint('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class CourseAttendance {
  final String subject;
  final int attended;
  final int total;
  final double percentage;
  final bool isWarning;

  CourseAttendance({
    required this.subject,
    required this.attended,
    required this.total,
    required this.percentage,
    required this.isWarning,
  });
} 