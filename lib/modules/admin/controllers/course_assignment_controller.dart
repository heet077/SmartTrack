import 'package:get/get.dart';
import '../models/course_assignment_model.dart';
import '../../../services/supabase_service.dart';

class CourseAssignmentController extends GetxController {
  final isLoading = false.obs;
  final error = ''.obs;
  final searchQuery = ''.obs;
  final selectedDay = 0.obs; // 0 means all days, 1-5 for Mon-Fri
  final assignments = <CourseAssignment>[].obs;
  final availableClassrooms = ['CEP-101', 'CEP-102', 'CEP-103', 'CEP-104', 'CEP-105', 'CEP-106', 'CEP-107', 'CEP-108', 'CEP-201', 'CEP-202', 'CEP-203', 'CEP-204', 'CEP-205'].obs;

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
    return assignments.where((assignment) {
      // First filter by search query
      final matchesSearch = 
          (assignment.courseName?.toLowerCase() ?? '').contains(searchQuery.value.toLowerCase()) ||
          (assignment.courseCode?.toLowerCase() ?? '').contains(searchQuery.value.toLowerCase()) ||
          (assignment.instructorName?.toLowerCase() ?? '').contains(searchQuery.value.toLowerCase());

      // Then filter by selected day if not "All Days"
      final matchesDay = selectedDay.value == 0 || 
          assignment.scheduleSlots.any((slot) => slot.dayOfWeek == selectedDay.value);

      return matchesSearch && matchesDay;
    }).toList();
  }

  Future<void> loadAssignments() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('instructor_course_assignments')
          .select('''
            *,
            instructor:instructors (
              id,
              name,
              email
            ),
            course:courses (
              id,
              code,
              name,
              credits,
              semester,
              program:programs (
                id,
                name
              )
            ),
            schedule:course_schedule_slots (
              id,
              classroom,
              day_of_week,
              start_time,
              end_time
            )
          ''')
          .order('created_at');

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

      // First create the instructor course assignment
      final assignmentResponse = await SupabaseService.client
          .from('instructor_course_assignments')
          .insert({
            ...assignment.toMap(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Then create the schedule slots
      for (var slot in assignment.scheduleSlots) {
        await SupabaseService.client
            .from('course_schedule_slots')
            .insert({
              ...slot.toMap(),
              'assignment_id': assignmentResponse['id'],
            });
      }

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

      // Update the instructor course assignment
      await SupabaseService.client
          .from('instructor_course_assignments')
          .update(assignment.toMap())
          .eq('id', assignment.id);

      // Delete existing schedule slots
      await SupabaseService.client
          .from('course_schedule_slots')
          .delete()
          .eq('assignment_id', assignment.id);

      // Create new schedule slots
      for (var slot in assignment.scheduleSlots) {
        await SupabaseService.client
            .from('course_schedule_slots')
            .insert({
              ...slot.toMap(),
              'assignment_id': assignment.id,
            });
      }

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

      // Delete schedule slots first (foreign key constraint)
      await SupabaseService.client
          .from('course_schedule_slots')
          .delete()
          .eq('assignment_id', id);

      // Then delete the assignment
      await SupabaseService.client
          .from('instructor_course_assignments')
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
} 