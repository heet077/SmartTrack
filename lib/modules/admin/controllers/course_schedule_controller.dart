import 'package:get/get.dart';
import '../models/course_schedule_model.dart';
import '../../../services/supabase_service.dart';

class CourseScheduleController extends GetxController {
  final RxList<CourseSchedule> schedules = <CourseSchedule>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<String> availableClassrooms = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
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

  List<CourseSchedule> get filteredSchedules {
    if (searchQuery.value.isEmpty) return schedules;
    final query = searchQuery.value.toLowerCase();
    return schedules.where((schedule) {
      return schedule.courseCode?.toLowerCase().contains(query) == true ||
          schedule.courseName?.toLowerCase().contains(query) == true ||
          schedule.instructorName?.toLowerCase().contains(query) == true ||
          schedule.classroom.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadSchedules() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('course_schedule_slots')
          .select('''
            *,
            assignment:instructor_course_assignments (
              id,
              instructor:instructors (
                id,
                name
              ),
              course:courses (
                id,
                code,
                name
              )
            )
          ''')
          .order('day_of_week');

      final List<CourseSchedule> loadedSchedules = (response as List)
          .map((data) => CourseSchedule.fromMap(data))
          .toList();
      
      schedules.value = loadedSchedules;
    } catch (e) {
      error.value = 'Failed to load course schedules';
      print('Error loading course schedules: $e');
      Get.snackbar(
        'Error',
        'Failed to load course schedules',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSchedule(CourseSchedule schedule) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Check for schedule conflicts
      if (await hasConflict(schedule)) {
        throw Exception('Schedule conflict detected');
      }

      await SupabaseService.client
          .from('course_schedule_slots')
          .insert(schedule.toMap());

      Get.back();
      Get.snackbar(
        'Success',
        'Course schedule added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadSchedules();
    } catch (e) {
      error.value = 'Failed to add course schedule';
      print('Error adding course schedule: $e');
      Get.snackbar(
        'Error',
        'Failed to add course schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSchedule(CourseSchedule schedule) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Check for schedule conflicts
      if (await hasConflict(schedule)) {
        throw Exception('Schedule conflict detected');
      }

      await SupabaseService.client
          .from('course_schedule_slots')
          .update(schedule.toMap())
          .eq('id', schedule.id);

      Get.back();
      Get.snackbar(
        'Success',
        'Course schedule updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadSchedules();
    } catch (e) {
      error.value = 'Failed to update course schedule';
      print('Error updating course schedule: $e');
      Get.snackbar(
        'Error',
        'Failed to update course schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('course_schedule_slots')
          .delete()
          .eq('id', id);

      Get.back();
      Get.snackbar(
        'Success',
        'Course schedule deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      schedules.removeWhere((schedule) => schedule.id == id);
    } catch (e) {
      error.value = 'Failed to delete course schedule';
      print('Error deleting course schedule: $e');
      Get.snackbar(
        'Error',
        'Failed to delete course schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> hasConflict(CourseSchedule newSchedule) async {
    try {
      // Get all schedules for the same day
      final response = await SupabaseService.client
          .from('course_schedule_slots')
          .select()
          .eq('day_of_week', newSchedule.dayOfWeek)
          .eq('classroom', newSchedule.classroom)
          .neq('id', newSchedule.id);

      final existingSchedules = (response as List)
          .map((data) => CourseSchedule.fromMap(data))
          .toList();

      for (var schedule in existingSchedules) {
        // Convert times to comparable format
        var newStart = _parseTime(newSchedule.startTime);
        var newEnd = _parseTime(newSchedule.endTime);
        var existingStart = _parseTime(schedule.startTime);
        var existingEnd = _parseTime(schedule.endTime);

        // Check if times overlap
        if ((!newStart.isBefore(existingStart) && newStart.isBefore(existingEnd)) ||
            (newEnd.isAfter(existingStart) && !newEnd.isAfter(existingEnd)) ||
            (!newStart.isAfter(existingStart) && !newEnd.isBefore(existingEnd))) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking schedule conflicts: $e');
      return false;
    }
  }

  // Helper method to parse time string to DateTime
  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
} 