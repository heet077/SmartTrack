import 'package:get/get.dart';
import '../models/course_assignment_model.dart';
import '../../../services/supabase_service.dart';

class CourseAssignmentController extends GetxController {
  final RxList<CourseAssignment> assignments = <CourseAssignment>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAssignments();
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
              semester
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

  Future<void> addAssignment(CourseAssignment assignment) async {
    try {
      isLoading.value = true;
      error.value = '';

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
} 