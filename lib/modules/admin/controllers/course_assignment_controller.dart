import 'package:get/get.dart';
import '../models/course_assignment_model.dart';
import '../../../services/supabase_service.dart';

class CourseAssignmentController extends GetxController {
  final RxList<CourseAssignment> assignments = <CourseAssignment>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> availableClassrooms = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAssignments();
    _initializeClassrooms();
  }

  void _initializeClassrooms() {
    // Generate classroom numbers CEP101-110 and CEP201-210
    final classrooms = <String>[];
    for (int i = 1; i <= 10; i++) {
      classrooms.add('CEP ${i < 10 ? '10$i' : '1$i'}');
    }
    for (int i = 1; i <= 10; i++) {
      classrooms.add('CEP ${i < 10 ? '20$i' : '2$i'}');
    }
    availableClassrooms.value = classrooms;
  }

  List<CourseAssignment> get filteredAssignments {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return assignments;
    return assignments.where((assignment) {
      return assignment.courseName?.toLowerCase().contains(query) == true ||
          assignment.instructorName?.toLowerCase().contains(query) == true ||
          assignment.classroom.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadAssignments() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('course_assignments')
          .select('''
            *,
            instructors (
              id,
              name,
              email
            ),
            courses!course_assignments_course_id_fkey (
              id,
              code,
              name,
              credits,
              semester,
              program:programs (
                id,
                name
              )
            )
          ''')
          .order('day_of_week');

      final List<CourseAssignment> loadedAssignments = (response as List)
          .map((data) => CourseAssignment.fromMap(data))
          .toList();
      
      assignments.value = loadedAssignments;
    } catch (e) {
      error.value = 'Failed to load course assignments';
      print('Error loading course assignments: $e');
      Get.snackbar(
        'Error',
        'Failed to load course assignments',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get courses available for an instructor based on their program assignments
  Future<List<Map<String, dynamic>>> getAvailableCoursesForInstructor(String instructorId) async {
    try {
      // First get the instructor's program assignments
      final programAssignments = await SupabaseService.client
          .from('instructor_program_mappings')
          .select('program_id')
          .eq('instructor_id', instructorId);

      final programIds = (programAssignments as List)
          .map((a) => a['program_id'] as String)
          .toList();

      if (programIds.isEmpty) {
        return [];
      }

      // Then get courses for those programs
      final courses = await SupabaseService.client
          .from('courses')
          .select('''
            *,
            program:programs (
              id,
              name
            )
          ''')
          .filter('program_id', 'in', programIds)
          .order('name');

      return courses;
    } catch (e) {
      print('Error getting available courses: $e');
      return [];
    }
  }

  Future<void> addAssignment(CourseAssignment assignment) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Verify instructor has access to this course's program
      final courseData = await SupabaseService.client
          .from('courses')
          .select('program_id')
          .eq('id', assignment.courseId)
          .single();

      final programId = courseData['program_id'];

      final instructorPrograms = await SupabaseService.client
          .from('instructor_program_mappings')
          .select('program_id')
          .eq('instructor_id', assignment.instructorId);

      final hasAccess = (instructorPrograms as List)
          .map((p) => p['program_id'] as String)
          .contains(programId);

      if (!hasAccess) {
        throw Exception('Instructor does not have access to this program\'s courses');
      }

      await SupabaseService.client
          .from('course_assignments')
          .insert(assignment.toMap());

      Get.back();
      Get.snackbar(
        'Success',
        'Course assignment added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadAssignments();
    } catch (e) {
      error.value = 'Failed to add course assignment';
      print('Error adding course assignment: $e');
      Get.snackbar(
        'Error',
        'Failed to add course assignment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAssignment(CourseAssignment assignment) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Verify instructor has access to this course's program
      final courseData = await SupabaseService.client
          .from('courses')
          .select('program_id')
          .eq('id', assignment.courseId)
          .single();

      final programId = courseData['program_id'];

      final instructorPrograms = await SupabaseService.client
          .from('instructor_program_mappings')
          .select('program_id')
          .eq('instructor_id', assignment.instructorId);

      final hasAccess = (instructorPrograms as List)
          .map((p) => p['program_id'] as String)
          .contains(programId);

      if (!hasAccess) {
        throw Exception('Instructor does not have access to this program\'s courses');
      }

      await SupabaseService.client
          .from('course_assignments')
          .update(assignment.toMap())
          .eq('id', assignment.id);

      Get.back();
      Get.snackbar(
        'Success',
        'Course assignment updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadAssignments();
    } catch (e) {
      error.value = 'Failed to update course assignment';
      print('Error updating course assignment: $e');
      Get.snackbar(
        'Error',
        'Failed to update course assignment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAssignment(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('course_assignments')
          .delete()
          .eq('id', id);

      Get.back();
      Get.snackbar(
        'Success',
        'Course assignment deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      assignments.removeWhere((assignment) => assignment.id == id);
    } catch (e) {
      error.value = 'Failed to delete course assignment';
      print('Error deleting course assignment: $e');
      Get.snackbar(
        'Error',
        'Failed to delete course assignment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkMscITAssignments() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('course_assignments')
          .select('''
            *,
            courses!inner (
              id,
              name,
              program:programs!inner (
                id,
                name
              )
            )
          ''')
          .eq('courses.program.name', 'M.Sc (IT)');

      print('MSc IT Course Assignments:');
      for (var assignment in response) {
        print('Course: ${assignment['courses']['name']}');
        print('Program: ${assignment['courses']['program']['name']}');
        print('Day: ${assignment['day_of_week']}');
        print('Time: ${assignment['start_time']} - ${assignment['end_time']}');
        print('---');
      }
    } catch (e) {
      print('Error checking MSc IT assignments: $e');
    } finally {
      isLoading.value = false;
    }
  }
} 