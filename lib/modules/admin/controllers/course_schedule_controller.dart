import 'package:get/get.dart';
import '../models/course_schedule_model.dart';
import '../../../services/supabase_service.dart';
import 'package:flutter/material.dart';

class CourseScheduleController extends GetxController {
  final isLoading = false.obs;
  final error = ''.obs;
  final searchQuery = ''.obs;
  final selectedDay = 0.obs; // 0 means all days, 1-5 for Mon-Fri
  final schedules = <CourseSchedule>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
  }

  List<CourseSchedule> get filteredSchedules {
    return schedules.where((schedule) {
      final matchesSearch = 
          (schedule.courseName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (schedule.courseCode ?? '').toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (schedule.instructorName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase());

      final matchesDay = selectedDay.value == 0 || schedule.dayOfWeek == selectedDay.value;

      return matchesSearch && matchesDay;
    }).toList();
  }

  Future<void> loadSchedules() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('course_schedule_slots')
          .select('''
            id,
            assignment_id,
            day_of_week,
            start_time,
            end_time,
            classroom,
            instructor_course_assignments (
              instructor_id,
              course_id,
              courses (
                id,
                code,
                name
              ),
              instructors (
                id,
                name
              )
            )
          ''')
          .order('day_of_week')
          .order('start_time');

      final List<CourseSchedule> loadedSchedules = [];
      for (final record in response) {
        try {
          final schedule = CourseSchedule.fromMap(record);
          loadedSchedules.add(schedule);
        } catch (e) {
          print('Error parsing schedule: $e');
        }
      }
      
      schedules.value = loadedSchedules;
    } catch (e) {
      error.value = 'Failed to load schedules: $e';
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