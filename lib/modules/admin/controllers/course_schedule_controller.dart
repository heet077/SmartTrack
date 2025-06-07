import 'package:get/get.dart';
import '../models/course_schedule_model.dart';

class CourseScheduleController extends GetxController {
  final RxList<CourseSchedule> schedules = <CourseSchedule>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
  }

  // Load course schedules (currently with mock data)
  Future<void> loadSchedules() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      schedules.value = [
        CourseSchedule(
          id: '1',
          courseCode: 'CS301',
          courseName: 'Data Structures',
          instructorName: 'Dr. Sharma',
          instructorId: 'INS001',
          days: ['Monday', 'Wednesday'],
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          room: 'Room B-204',
        ),
        CourseSchedule(
          id: '2',
          courseCode: 'CS302',
          courseName: 'Database Systems',
          instructorName: 'Dr. Patel',
          instructorId: 'INS002',
          days: ['Tuesday', 'Thursday'],
          startTime: '2:00 PM',
          endTime: '3:00 PM',
          room: 'Room A-101',
        ),
      ];
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load course schedules',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter schedules based on search query
  List<CourseSchedule> get filteredSchedules {
    if (searchQuery.value.isEmpty) return schedules;
    return schedules.where((schedule) {
      final query = searchQuery.value.toLowerCase();
      return schedule.courseCode.toLowerCase().contains(query) ||
          schedule.courseName.toLowerCase().contains(query) ||
          schedule.instructorName.toLowerCase().contains(query) ||
          schedule.room.toLowerCase().contains(query);
    }).toList();
  }

  // Add new course schedule
  Future<void> addSchedule(CourseSchedule schedule) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      schedules.add(schedule);
      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Course schedule added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add course schedule',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete course schedule
  Future<void> deleteSchedule(String id) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      schedules.removeWhere((schedule) => schedule.id == id);
      Get.snackbar(
        'Success',
        'Course schedule deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete course schedule',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Check for schedule conflicts
  bool hasConflict(CourseSchedule newSchedule) {
    for (var schedule in schedules) {
      if (schedule.id != newSchedule.id) {
        // Check if days overlap
        bool daysOverlap = schedule.days.any((day) => newSchedule.days.contains(day));
        if (daysOverlap) {
          // Convert times to comparable format (24-hour)
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
      }
    }
    return false;
  }

  // Helper method to parse time string to DateTime
  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    
    if (parts[1] == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1] == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
} 