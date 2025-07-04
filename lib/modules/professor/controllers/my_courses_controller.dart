import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class Course {
  final String id;
  final String code;
  final String name;
  final int semester;
  final int credits;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  RxDouble requiredAttendance;
  RxInt totalStudents;
  RxDouble currentAttendanceRate;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.semester,
    required this.credits,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required double requiredAttendance,
    required int totalStudents,
    required double currentAttendanceRate,
  })  : requiredAttendance = requiredAttendance.obs,
        totalStudents = totalStudents.obs,
        currentAttendanceRate = currentAttendanceRate.obs;

  static Course fromMap(Map<String, dynamic> assignment) {
    final courseData = assignment['course'] as Map<String, dynamic>;
    
    return Course(
      id: (courseData['id'] ?? '').toString(),
      code: (courseData['code'] ?? '').toString(),
      name: (courseData['name'] ?? '').toString(),
      semester: int.parse((courseData['semester'] ?? '0').toString()),
      credits: int.parse((courseData['credits'] ?? '0').toString()),
      classroom: (assignment['classroom'] ?? 'TBD').toString(),
      dayOfWeek: int.parse((assignment['day_of_week'] ?? '1').toString()),
      startTime: (assignment['start_time'] ?? '00:00').toString(),
      endTime: (assignment['end_time'] ?? '00:00').toString(),
      requiredAttendance: 0.75,
      totalStudents: 0,
      currentAttendanceRate: 0.0,
    );
  }
}

class MyCoursesController extends GetxController {
  final RxList<Course> courses = <Course>[].obs;
  final supabase = Supabase.instance.client;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAssignedCourses();
  }

  Future<void> fetchAssignedCourses() async {
    try {
      isLoading.value = true;
      
      // Get the current instructor's ID
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (userEmail == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      // Get instructor details
      final instructor = await supabase
          .from('instructors')
          .select()
          .match({'email': userEmail as Object})
          .single();

      // Fetch assigned courses with their details
      final assignedCourses = await supabase
          .from('course_assignments')
          .select('''
            id,
            course:courses!course_assignments_course_id_fkey (
              id, name, code, semester, credits
            ),
            classroom,
            day_of_week,
            start_time,
            end_time
          ''')
          .match({'instructor_id': instructor['id'] as Object});

      final List<Course> loadedCourses = [];
      
      // Create a Set to track unique course IDs
      final Set<String> uniqueCourseIds = {};
      
      for (final assignment in assignedCourses) {
        final course = Course.fromMap(assignment);
        
        // Only add the course if we haven't seen its ID before
        if (!uniqueCourseIds.contains(course.id)) {
          uniqueCourseIds.add(course.id);
        
        try {
          // Get attendance rule for this course
          final rules = await supabase
              .from('instructor_attendance_rules')
              .select()
              .match({
                'instructor_id': instructor['id'] as Object,
                'course_id': course.id as Object,
              });

          if (rules.isNotEmpty) {
            course.requiredAttendance.value = rules[0]['min_attendance'] ?? 0.75;
          }

          // Calculate total students from attendance_records
          final studentsResponse = await supabase
              .from('attendance_records')
              .select('student_id')
              .eq('course_id', course.id as Object);
          
          // Get unique student count
          final uniqueStudents = (studentsResponse as List)
              .map((record) => record['student_id'])
              .toSet()
              .length;
          
          course.totalStudents.value = uniqueStudents;

          // Calculate attendance rate from attendance_records
          final attendanceResponse = await supabase
              .from('attendance_records')
              .select()
              .eq('course_id', course.id as Object)
              .eq('status', 'present');

          if (uniqueStudents > 0) {
            final totalSessions = await supabase
                .from('lecture_sessions')
                .select('id')
                .eq('course_id', course.id as Object);

            final totalPresentRecords = (attendanceResponse as List).length;
            final totalPossibleAttendances = uniqueStudents * (totalSessions as List).length;
            
            course.currentAttendanceRate.value = totalPossibleAttendances > 0
                ? totalPresentRecords / totalPossibleAttendances
                : 0.0;
          }
        } catch (e) {
          print('Error loading course details: $e');
        }

        loadedCourses.add(course);
        }
      }
      
      courses.value = loadedCourses;
    } catch (e) {
      print('Error loading courses: $e');
      Get.snackbar('Error', 'Failed to load courses');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRequiredAttendance(String courseId, double newValue) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) return;

      final instructor = await supabase
          .from('instructors')
          .select()
          .eq('email', user.email as Object)
          .single();

      // Update or insert attendance rule
      final existingRule = await supabase
          .from('instructor_attendance_rules')
          .select()
          .eq('instructor_id', instructor['id'])
          .eq('course_id', courseId);

      if (existingRule.isEmpty) {
        await supabase.from('instructor_attendance_rules').insert({
          'instructor_id': instructor['id'],
          'course_id': courseId,
          'min_attendance': newValue,
        });
      } else {
        await supabase
            .from('instructor_attendance_rules')
            .update({'min_attendance': newValue})
            .eq('instructor_id', instructor['id'])
            .eq('course_id', courseId);
      }

      final courseIndex = courses.indexWhere((c) => c.id == courseId);
      if (courseIndex != -1) {
        courses[courseIndex].requiredAttendance.value = newValue;
      }

      Get.snackbar('Success', 'Attendance requirement updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update attendance requirement: ${e.toString()}');
    }
  }
} 