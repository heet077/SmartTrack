import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AttendanceController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxString selectedCourse = ''.obs;
  final RxString selectedDate = ''.obs;
  final RxBool isLoading = false.obs;
  
  final RxList<Map<String, dynamic>> courses = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> attendanceData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfessorCourses();
  }

  Future<void> loadProfessorCourses() async {
    try {
      isLoading.value = true;
      
      // Get current user's ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      // Fetch assigned courses
      final coursesData = await _supabase
          .from('course_assignments')
          .select('''
            *,
            course:courses (
              id, code, name
            )
          ''')
          .eq('instructor_id', currentUser.id);

      courses.value = coursesData.map<Map<String, dynamic>>((assignment) {
        final course = assignment['course'];
        return {
          'code': course['code'],
          'name': course['name'],
          'id': course['id']
        };
      }).toList();

      if (courses.isNotEmpty) {
        selectedCourse.value = courses[0]['code'];
        await loadAttendanceData(courses[0]['id']);
      }

      // Set current date
      final now = DateTime.now();
      selectedDate.value = '${now.day}/${now.month}/${now.year}';

    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAttendanceData(String courseId) async {
    try {
      isLoading.value = true;

      // Get today's date
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get today's attendance records
      final attendanceRecords = await _supabase
          .from('attendance_records')
          .select('''
            *,
            student:students (
              id, name, roll_number
            )
          ''')
          .eq('course_id', courseId)
          .eq('date', today);

      // Get total enrolled students
      final enrolledStudents = await _supabase
          .from('course_enrollments')
          .select('''
            *,
            student:students (
              id, name, roll_number
            )
          ''')
          .eq('course_id', courseId);

      // Process attendance data
      final totalStudents = enrolledStudents.length;
      final presentStudents = attendanceRecords.where((record) => record['status'] == 'present').length;
      final absentStudents = totalStudents - presentStudents;

      // Create students list with attendance status
      final students = enrolledStudents.map((enrollment) {
        final student = enrollment['student'];
        final attendanceRecord = attendanceRecords.firstWhere(
          (record) => record['student_id'] == student['id'],
          orElse: () => {'status': 'absent'}
        );

        return {
          'name': student['name'],
          'rollNumber': student['roll_number'],
          'status': attendanceRecord['status']
        };
      }).toList();

      attendanceData[courseId] = {
        'total': totalStudents,
        'present': presentStudents,
        'absent': absentStudents,
        'students': students,
      };

      attendanceData.refresh();

    } catch (e) {
      debugPrint('Error loading attendance data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> get currentAttendance {
    final courseId = courses.firstWhere(
      (course) => course['code'] == selectedCourse.value,
      orElse: () => {'id': ''}
    )['id'];
    
    return courseId.isNotEmpty ? attendanceData[courseId] ?? {} : {};
  }
  
  List<Map<String, dynamic>> get currentStudents => 
      List<Map<String, dynamic>>.from(currentAttendance['students'] ?? []);

  void changeCourse(String courseCode) {
    selectedCourse.value = courseCode;
    final courseId = courses.firstWhere(
      (course) => course['code'] == courseCode,
      orElse: () => {'id': ''}
    )['id'];
    
    if (courseId.isNotEmpty) {
      loadAttendanceData(courseId);
    }
  }
} 