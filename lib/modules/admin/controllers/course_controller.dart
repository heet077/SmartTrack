import 'package:get/get.dart';
import '../models/course_model.dart';
import '../../../services/supabase_service.dart';

class CourseController extends GetxController {
  final RxList<Course> courses = <Course>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  List<Course> get filteredCourses {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return courses;
    return courses.where((course) =>
      course.name.toLowerCase().contains(query) ||
      course.code.toLowerCase().contains(query)
    ).toList();
  }

  Future<void> loadCourses() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('courses')
          .select()
          .order('name');
      
      final List<Course> loadedCourses = (response as List)
          .map((data) => Course.fromMap(data))
          .toList();
      
      courses.value = loadedCourses;
    } catch (e) {
      error.value = 'Failed to load courses';
      print('Error loading courses: $e');
      Get.snackbar(
        'Error',
        'Failed to load courses',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCourse(Course course) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client.from('courses').insert({
        'name': course.name,
        'code': course.code,
        'credits': course.credits,
        'program_id': course.programId,
        'semester': course.semester,
      });

      Get.back(); // Close the add dialog
      Get.snackbar(
        'Success',
        'Course added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadCourses(); // Reload to get the new list
    } catch (e) {
      error.value = 'Failed to add course';
      print('Error adding course: $e');
      Get.snackbar(
        'Error',
        'Failed to add course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('courses')
          .update({
            'name': course.name,
            'code': course.code,
            'credits': course.credits,
            'program_id': course.programId,
            'semester': course.semester,
          })
          .eq('id', course.id);

      Get.back(); // Close the edit dialog
      Get.snackbar(
        'Success',
        'Course updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadCourses(); // Reload to get updated data
    } catch (e) {
      error.value = 'Failed to update course';
      print('Error updating course: $e');
      Get.snackbar(
        'Error',
        'Failed to update course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('courses')
          .delete()
          .eq('id', id);

      Get.back(); // Close the confirmation dialog
      Get.snackbar(
        'Success',
        'Course deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Remove from local list
      courses.removeWhere((course) => course.id == id);
    } catch (e) {
      error.value = 'Failed to delete course';
      print('Error deleting course: $e');
      Get.snackbar(
        'Error',
        'Failed to delete course',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 