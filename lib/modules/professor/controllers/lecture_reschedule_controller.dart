import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../services/supabase_service.dart';
import '../models/lecture_reschedule.dart';
import '../models/lecture_session.dart';
import 'package:retry/retry.dart';

class LectureRescheduleController extends GetxController {
  final isLoading = false.obs;
  final error = ''.obs;
  final selectedDate = Rx<DateTime?>(null);
  final selectedTime = Rx<DateTime?>(null);
  final selectedClassroom = ''.obs;
  final conflictingLecture = Rx<Map<String, dynamic>?>(null);
  final isSlotAvailable = false.obs;

  final _uuid = const Uuid();

  // List of available classrooms
  final List<String> classrooms = [
    // CEP 101-110
    ...List.generate(10, (i) => 'CEP-${(i + 101).toString()}'),
    // CEP 201-210
    ...List.generate(10, (i) => 'CEP-${(i + 201).toString()}'),
  ];

  // Helper method to parse time string to DateTime with a fixed date
  DateTime _parseTimeStringFixed(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        // Validate hour and minute ranges
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(2000, 1, 1, hour, minute);
        } else {
          print('Invalid time values: hour=$hour, minute=$minute');
          return DateTime(2000, 1, 1, 0, 0);
        }
      } else {
        print('Invalid time format: $timeStr');
        return DateTime(2000, 1, 1, 0, 0);
      }
    } catch (e) {
      print('Error parsing time string "$timeStr": $e');
      return DateTime(2000, 1, 1, 0, 0);
    }
  }

  Future<void> checkTimeSlotAvailability(DateTime dateTime, String classroom, int durationMinutes) async {
    print('=== CHECKING TIME SLOT AVAILABILITY ===');
    print('DateTime: $dateTime');
    print('Classroom: $classroom');
    print('Duration: $durationMinutes minutes');
    print('Weekday: ${dateTime.weekday}');
    
    try {
      isLoading.value = true;
      error.value = '';
      conflictingLecture.value = null;
      isSlotAvailable.value = false;

      final dateString = dateTime.toIso8601String().split('T')[0]; // Extract just the date
      final weekday = dateTime.weekday;

      print('Date string: $dateString');
      print('Weekday: $weekday');

      // 1. Check ALL regular scheduled slots for conflicts (not just the current course)
      final scheduleResponse = await SupabaseService.client
          .from('course_schedule_slots')
          .select('''
            *,
            instructor_course_assignments (
              instructor:instructors (
                id, name
              ),
              course:courses (
                id, name, code
              )
            )
          ''')
          .eq('classroom', classroom)
          .eq('day_of_week', weekday);

      print('Schedule response: $scheduleResponse');
      print('Number of slots found: ${(scheduleResponse as List).length}');

      if ((scheduleResponse as List).isNotEmpty) {
        // Check each schedule for time overlap with ANY course
        for (final slot in scheduleResponse) {
          final startTime = _parseTimeStringFixed(slot['start_time']);
          final endTime = _parseTimeStringFixed(slot['end_time']);
          final newStartTime = _parseTimeStringFixed('${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00');
          final newEndTime = newStartTime.add(Duration(minutes: durationMinutes));
          
          print('Checking slot: ${slot['start_time']} - ${slot['end_time']}');
          print('New slot: ${newStartTime.hour}:${newStartTime.minute} - ${newEndTime.hour}:${newEndTime.minute}');
          print('Overlap: ${_timesOverlap(startTime, endTime, newStartTime, newEndTime)}');
          
          if (_timesOverlap(startTime, endTime, newStartTime, newEndTime)) {
            final courseName = slot['instructor_course_assignments']['course']['name'];
            final instructorName = slot['instructor_course_assignments']['instructor']['name'];
            final courseCode = slot['instructor_course_assignments']['course']['code'];
            
            print('CONFLICT FOUND: $courseCode ($courseName) by Prof. $instructorName');
            
            conflictingLecture.value = {
              'type': 'regular',
              'instructor': slot['instructor_course_assignments']['instructor'],
              'course': slot['instructor_course_assignments']['course'],
              'start_time': slot['start_time'],
              'end_time': slot['end_time'],
              'classroom': classroom,
              'message': 'Slot is not free. Conflicts with $courseCode ($courseName) by Prof. $instructorName at ${slot['start_time']} - ${slot['end_time']}.'
            };
            error.value = conflictingLecture.value!['message'];
            isSlotAvailable.value = false;
            return;
          }
        }
      } else {
        print('No scheduled slots found for classroom $classroom on weekday $weekday');
      }

      // 2. Check lecture reschedules on that date (only 1 allowed per day)
      final rescheduledResponse = await SupabaseService.client
          .from('lecture_reschedules')
          .select('''
            *,
            instructor:instructors (
              id, name
            ),
            course:courses (
              id, name, code
            )
          ''')
          .eq('classroom', classroom)
          .eq('rescheduled_datetime::date', dateString)
          .gte('expiry_date', DateTime.now().toIso8601String());

      print('Rescheduled response: $rescheduledResponse');
      print('Number of rescheduled slots found: ${(rescheduledResponse as List).length}');

      if ((rescheduledResponse as List).isNotEmpty) {
        final reschedule = rescheduledResponse.first;
        print('RESCHEDULE CONFLICT FOUND: ${reschedule['course']['name']} by ${reschedule['instructor']['name']}');
        
        conflictingLecture.value = {
          'type': 'rescheduled',
          'instructor': reschedule['instructor'],
          'course': reschedule['course'],
          'start_time': reschedule['rescheduled_datetime'],
          'end_time': reschedule['end_time'],
          'classroom': classroom,
          'message': 'Slot is not free. A rescheduled lecture already exists in this classroom on this date.'
        };
        error.value = conflictingLecture.value!['message'];
        isSlotAvailable.value = false;
        return;
      }

      // ✅ No conflicts found
      print('NO CONFLICTS FOUND - Slot is available!');
      isSlotAvailable.value = true;
      conflictingLecture.value = null;
      error.value = '';

    } catch (e) {
      print('Error checking time slot: $e');
      error.value = 'Failed to check time slot availability.';
      isSlotAvailable.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Additional method to get all conflicts for a specific time slot
  Future<List<Map<String, dynamic>>> getAllConflicts(DateTime dateTime, String classroom, int durationMinutes) async {
    final conflicts = <Map<String, dynamic>>[];
    
    try {
      final weekday = dateTime.weekday;
      
      // Check regular scheduled slots
      final scheduleResponse = await SupabaseService.client
          .from('course_schedule_slots')
          .select('''
            *,
            instructor_course_assignments (
              instructor:instructors (
                id, name
              ),
              course:courses (
                id, name, code
              )
            )
          ''')
          .eq('classroom', classroom)
          .eq('day_of_week', weekday);

      if ((scheduleResponse as List).isNotEmpty) {
        for (final slot in scheduleResponse) {
          final startTime = _parseTimeStringFixed(slot['start_time']);
          final endTime = _parseTimeStringFixed(slot['end_time']);
          final newStartTime = _parseTimeStringFixed('${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00');
          final newEndTime = newStartTime.add(Duration(minutes: durationMinutes));
          
          if (_timesOverlap(startTime, endTime, newStartTime, newEndTime)) {
            conflicts.add({
              'type': 'regular',
              'instructor': slot['instructor_course_assignments']['instructor'],
              'course': slot['instructor_course_assignments']['course'],
              'start_time': slot['start_time'],
              'end_time': slot['end_time'],
              'classroom': classroom,
              'message': 'Conflicts with ${slot['instructor_course_assignments']['course']['code']} (${slot['instructor_course_assignments']['course']['name']}) by Prof. ${slot['instructor_course_assignments']['instructor']['name']} at ${slot['start_time']} - ${slot['end_time']}.'
            });
          }
        }
      }

      // Check rescheduled lectures
      final dateString = dateTime.toIso8601String().split('T')[0];
      final rescheduledResponse = await SupabaseService.client
          .from('lecture_reschedules')
          .select('''
            *,
            instructor:instructors (
              id, name
            ),
            course:courses (
              id, name, code
            )
          ''')
          .eq('classroom', classroom)
          .eq('rescheduled_datetime::date', dateString)
          .gte('expiry_date', DateTime.now().toIso8601String());

      if ((rescheduledResponse as List).isNotEmpty) {
        conflicts.add({
          'type': 'rescheduled',
          'instructor': rescheduledResponse.first['instructor'],
          'course': rescheduledResponse.first['course'],
          'start_time': rescheduledResponse.first['rescheduled_datetime'],
          'end_time': rescheduledResponse.first['end_time'],
          'classroom': classroom,
          'message': 'A rescheduled lecture already exists in this classroom on this date.'
        });
      }
      
    } catch (e) {
      print('Error getting all conflicts: $e');
    }
    
    return conflicts;
  }

  Future<void> rescheduleLecture(LectureSession lecture, DateTime newDateTime) async {
    final r = RetryOptions(maxAttempts: 3);
    try {
      isLoading.value = true;
      error.value = '';

      // Calculate expiry date (end of the week)
      final now = DateTime.now();
      final daysUntilSunday = DateTime.sunday - now.weekday;
      final expiryDate = now.add(Duration(days: daysUntilSunday));

      final durationMinutes = lecture.endTime.difference(lecture.startTime).inMinutes;

      final reschedule = LectureReschedule(
        id: _uuid.v4(),
        originalScheduleId: lecture.scheduleId,
        courseId: lecture.courseId,
        instructorId: lecture.instructorId,
        originalDateTime: lecture.startTime,
        rescheduledDateTime: newDateTime,
        classroom: selectedClassroom.value,
        expiryDate: expiryDate,
        createdAt: now,
      );

      // Insert the rescheduling record with retry logic
      await r.retry(
        () => SupabaseService.client
            .from('lecture_reschedules')
            .insert(reschedule.toMap()),
        retryIf: (e) => e.toString().contains('SocketException') || e.toString().contains('ClientException'),
      );

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Lecture rescheduled successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Failed to reschedule lecture';
      print('Error rescheduling lecture: $e');
      Get.snackbar(
        'Error',
        'Failed to reschedule lecture: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelRescheduling(String rescheduleId) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('lecture_reschedules')
          .delete()
          .eq('id', rescheduleId);

      Get.snackbar(
        'Success',
        'Rescheduling cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Failed to cancel rescheduling';
      print('Error cancelling rescheduling: $e');
      Get.snackbar(
        'Error',
        'Failed to cancel rescheduling: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to check if two time ranges overlap
  bool _timesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    // Check if the time ranges overlap
    // Two time ranges overlap if:
    // 1. start1 < end2 AND start2 < end1
    // 2. Or if they are exactly adjacent (one ends when another starts)
    
    final hasOverlap = start1.isBefore(end2) && start2.isBefore(end1);
    
    print('Time overlap check:');
    print('  Range 1: ${start1.hour}:${start1.minute} - ${end1.hour}:${end1.minute}');
    print('  Range 2: ${start2.hour}:${start2.minute} - ${end2.hour}:${end2.minute}');
    print('  Overlap: $hasOverlap');
    
    return hasOverlap;
  }

  // Test method to verify conflict detection
  Future<void> testConflictDetection() async {
    print('=== TESTING CONFLICT DETECTION ===');
    
    // Test with a known time slot
    final testDateTime = DateTime.now().add(const Duration(days: 1));
    final testClassroom = 'CEP-101';
    final testDuration = 50; // 50 minutes
    
    print('Testing with:');
    print('  Date: $testDateTime');
    print('  Classroom: $testClassroom');
    print('  Duration: $testDuration minutes');
    
    await checkTimeSlotAvailability(testDateTime, testClassroom, testDuration);
    
    print('Test completed. Slot available: ${isSlotAvailable.value}');
    if (conflictingLecture.value != null) {
      print('Conflict found: ${conflictingLecture.value!['message']}');
    }
  }

  // Method to get available time slots for a specific day and classroom
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(DateTime date, String classroom) async {
    final availableSlots = <Map<String, dynamic>>[];
    
    try {
      final weekday = date.weekday;
      
      // Get all scheduled slots for the day and classroom
      final scheduleResponse = await SupabaseService.client
          .from('course_schedule_slots')
          .select('''
            *,
            instructor_course_assignments (
              instructor:instructors (
                id, name
              ),
              course:courses (
                id, name, code
              )
            )
          ''')
          .eq('classroom', classroom)
          .eq('day_of_week', weekday);

      // Define possible time slots (assuming 50-minute periods)
      final timeSlots = [
        {'start': '08:00:00', 'end': '08:50:00'},
        {'start': '09:00:00', 'end': '09:50:00'},
        {'start': '10:00:00', 'end': '10:50:00'},
        {'start': '11:00:00', 'end': '11:50:00'},
        {'start': '12:00:00', 'end': '12:50:00'},
        {'start': '14:00:00', 'end': '14:50:00'},
        {'start': '15:00:00', 'end': '15:50:00'},
        {'start': '16:00:00', 'end': '16:50:00'},
      ];

      // Check each time slot for availability
      for (final slot in timeSlots) {
        final startTime = _parseTimeStringFixed(slot['start']!);
        final endTime = _parseTimeStringFixed(slot['end']!);
        
        bool isAvailable = true;
        String? conflictReason;

        // Check against scheduled slots
        for (final scheduledSlot in scheduleResponse) {
          final scheduledStart = _parseTimeStringFixed(scheduledSlot['start_time']);
          final scheduledEnd = _parseTimeStringFixed(scheduledSlot['end_time']);
          
          if (_timesOverlap(scheduledStart, scheduledEnd, startTime, endTime)) {
            isAvailable = false;
            final courseName = scheduledSlot['instructor_course_assignments']['course']['name'];
            final instructorName = scheduledSlot['instructor_course_assignments']['instructor']['name'];
            conflictReason = 'Conflicts with $courseName by Prof. $instructorName';
            break;
          }
        }

        if (isAvailable) {
          availableSlots.add({
            'start_time': slot['start'],
            'end_time': slot['end'],
            'available': true,
          });
        } else {
          availableSlots.add({
            'start_time': slot['start'],
            'end_time': slot['end'],
            'available': false,
            'conflict_reason': conflictReason,
          });
        }
      }
      
    } catch (e) {
      print('Error getting available time slots: $e');
    }
    
    return availableSlots;
  }
} 