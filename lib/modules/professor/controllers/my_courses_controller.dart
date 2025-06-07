import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      id: courseData['id'],
      code: courseData['code'],
      name: courseData['name'],
      semester: courseData['semester'],
      credits: courseData['credits'],
      classroom: assignment['classroom'] ?? 'TBD',
      dayOfWeek: assignment['day_of_week'] ?? 1,
      startTime: assignment['start_time'] ?? '00:00',
      endTime: assignment['end_time'] ?? '00:00',
      requiredAttendance: 0.75, // Default value
      totalStudents: 0,  // Will be updated later
      currentAttendanceRate: 0.0, // Will be updated later
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
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      // Get instructor details
      final instructor = await supabase
          .from('instructors')
          .select()
          .eq('email', user.email)
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
          .eq('instructor_id', instructor['id']);

      final List<Course> loadedCourses = [];
      
      for (final assignment in assignedCourses) {
        final course = Course.fromMap(assignment);
        
        try {
          // Get attendance rule for this course
          final rules = await supabase
              .from('instructor_attendance_rules')
              .select()
              .eq('instructor_id', instructor['id'])
              .eq('course_id', course.id);

          if (rules.isNotEmpty) {
            course.requiredAttendance.value = rules[0]['min_attendance'] ?? 0.75;
          }

          // Calculate total students
          final studentsCount = await supabase
              .from('attendance_records')
              .select('student_id', const FetchOptions(count: CountOption.exact))
              .eq('session_id', supabase
                  .from('lecture_sessions')
                  .select('id')
                  .eq('course_id', course.id))
              .execute();

          course.totalStudents.value = studentsCount.count ?? 0;

          // Calculate attendance rate
          final attendanceData = await supabase
              .from('attendance_records')
              .select('present')
              .eq('session_id', supabase
                  .from('lecture_sessions')
                  .select('id')
                  .eq('course_id', course.id))
              .execute();

          if (attendanceData.data != null && attendanceData.data!.isNotEmpty) {
            final totalRecords = attendanceData.data!.length;
            final presentCount = attendanceData.data!
                .where((record) => record['present'] == true)
                .length;
            course.currentAttendanceRate.value = totalRecords > 0
                ? presentCount / totalRecords
                : 0.0;
          }
        } catch (e) {
          print('Error loading course details: $e');
        }

        loadedCourses.add(course);
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
      if (user == null) return;

      final instructor = await supabase
          .from('instructors')
          .select()
          .eq('email', user.email)
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