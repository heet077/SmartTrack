import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';

class AttendanceController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<Student> students = <Student>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString currentCourseId = ''.obs;
  final RxString currentCourseName = ''.obs;

  Future<void> loadStudentsForCourse(String courseId, String courseName) async {
    try {
      isLoading.value = true;
      error.value = '';
      currentCourseId.value = courseId;
      currentCourseName.value = courseName;

      // Get all students enrolled in this course
      final response = await supabase
          .from('course_enrollments')
          .select('''
            *,
            student:students (
              id,
              name,
              enrollment_no,
              email
            )
          ''')
          .eq('course_id', courseId);

      if (response != null) {
        students.value = (response as List)
            .map((data) => Student.fromJson(data['student']))
            .toList();

        // Get today's attendance records
        final today = DateTime.now().toIso8601String().split('T')[0];
        final attendanceRecords = await supabase
            .from('attendance')
            .select()
            .eq('course_id', courseId)
            .eq('date', today);

        // Mark students as present based on existing attendance records
        if (attendanceRecords != null) {
          final presentStudentIds = (attendanceRecords as List)
              .where((record) => record['is_present'])
              .map((record) => record['student_id'])
              .toSet();

          for (var student in students) {
            student.isPresent = presentStudentIds.contains(student.id);
          }
        }
      }
    } catch (e) {
      error.value = 'Error loading students: $e';
      print('Error loading students: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleAttendance(Student student) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Update the local state
      student.isPresent = !student.isPresent;
      students.refresh();

      // Update or insert attendance record
      await supabase.from('attendance').upsert({
        'course_id': currentCourseId.value,
        'student_id': student.id,
        'date': today,
        'is_present': student.isPresent,
      });
    } catch (e) {
      error.value = 'Error updating attendance: $e';
      print('Error updating attendance: $e');
      // Revert the local state change
      student.isPresent = !student.isPresent;
      students.refresh();
    }
  }

  Future<void> submitAttendance() async {
    try {
      isLoading.value = true;
      error.value = '';
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Prepare all attendance records
      final records = students.map((student) => {
        'course_id': currentCourseId.value,
        'student_id': student.id,
        'date': today,
        'is_present': student.isPresent,
      }).toList();

      // Submit all attendance records at once
      await supabase.from('attendance').upsert(records);
      
      Get.snackbar(
        'Success',
        'Attendance submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Error submitting attendance: $e';
      print('Error submitting attendance: $e');
      Get.snackbar(
        'Error',
        'Failed to submit attendance',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 