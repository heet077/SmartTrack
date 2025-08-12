import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/lecture_reschedule_controller.dart';
import '../models/lecture_session.dart';

class RescheduleLectureDialog extends StatelessWidget {
  final LectureSession lecture;
  final LectureRescheduleController controller;

  const RescheduleLectureDialog({
    Key? key,
    required this.lecture,
    required this.controller, required String lectureId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reset availability state when dialog opens
    controller.isSlotAvailable.value = false;
    controller.conflictingLecture.value = null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                'Reschedule Lecture',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture.courseName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Room ${lecture.classroom}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${lecture.startTime.hour}:${lecture.startTime.minute.toString().padLeft(2, '0')} - ${lecture.endTime.hour}:${lecture.endTime.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 7)),
                            );
                            if (date != null) {
                              controller.selectedDate.value = date;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Obx(() {
                                  final date = controller.selectedDate.value;
                                  return Text(
                                    date != null
                                        ? '${date.day}/${date.month}/${date.year}'
                                        : 'Select Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: date != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              final now = DateTime.now();
                              controller.selectedTime.value = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                time.hour,
                                time.minute,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Obx(() {
                                  final time = controller.selectedTime.value;
                                  return Text(
                                    time != null
                                        ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                        : 'Select Time',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: time != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: controller.selectedClassroom.value.isEmpty ? null : controller.selectedClassroom.value,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                        hintText: 'Select Classroom',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                      items: controller.classrooms.map((classroom) {
                        return DropdownMenuItem<String>(
                          value: classroom,
                          child: Text(
                            classroom,
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedClassroom.value = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (controller.error.value.isNotEmpty) {
                      return Text(
                        controller.error.value,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                        ),
                      );
                    }

                    final conflict = controller.conflictingLecture.value;
                    if (conflict != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Slot Not Available',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Conflicts with:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conflict['course']['name'] ?? 'Unknown Course',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                  Text(
                                    'by ${conflict['instructor']['name'] ?? 'Unknown Instructor'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  if (conflict['start_time'] != null && conflict['end_time'] != null)
                                    Text(
                                      'Time: ${conflict['start_time']} - ${conflict['end_time']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  Text(
                                    'Room: ${conflict['classroom']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.isSlotAvailable.value) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Text(
                          'Time Slot Available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }

                    return const SizedBox();
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final date = controller.selectedDate.value;
                            final time = controller.selectedTime.value;
                            final classroom = controller.selectedClassroom.value;
                            
                            if (date != null && time != null && classroom.isNotEmpty) {
                              final newDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              
                              // Get all conflicts for comprehensive display
                              final allConflicts = await controller.getAllConflicts(
                                newDateTime,
                                classroom,
                                lecture.endTime.difference(lecture.startTime).inMinutes,
                              );
                              
                              if (allConflicts.isNotEmpty) {
                                _showAllConflictsDialog(context, allConflicts);
                              } else {
                                Get.snackbar(
                                  'No Conflicts',
                                  'This time slot is available!',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green[100],
                                  colorText: Colors.green[800],
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Check All Conflicts',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final date = controller.selectedDate.value;
                            final classroom = controller.selectedClassroom.value;
                            
                            if (date != null && classroom.isNotEmpty) {
                              final availableSlots = await controller.getAvailableTimeSlots(date, classroom);
                              _showAvailableSlotsDialog(context, availableSlots, classroom);
                            } else {
                              Get.snackbar(
                                'Missing Information',
                                'Please select both date and classroom first.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange[100],
                                colorText: Colors.orange[800],
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Show Available Slots',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final canCheck = controller.selectedDate.value != null &&
                          controller.selectedTime.value != null &&
                          controller.selectedClassroom.value.isNotEmpty;

                      return ElevatedButton(
                        onPressed: canCheck
                            ? () {
                                final date = controller.selectedDate.value!;
                                final time = controller.selectedTime.value!;
                                final newDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                controller.checkTimeSlotAvailability(
                                  newDateTime,
                                  controller.selectedClassroom.value,
                                  lecture.endTime.difference(lecture.startTime).inMinutes,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCheck ? Colors.blue : Colors.grey[300],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Check',
                          style: GoogleFonts.poppins(
                            color: canCheck ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Obx(() {
                      final canReschedule = controller.isSlotAvailable.value;

                      return ElevatedButton(
                        onPressed: canReschedule
                            ? () {
                                final date = controller.selectedDate.value!;
                                final time = controller.selectedTime.value!;
                                final newDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                controller.rescheduleLecture(lecture, newDateTime);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canReschedule ? Colors.blue : Colors.grey[300],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Reschedule',
                          style: GoogleFonts.poppins(
                            color: canReschedule ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllConflictsDialog(BuildContext context, List<Map<String, dynamic>> conflicts) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Conflicts Found',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: conflicts.map((conflict) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict['course']['name'] ?? 'Unknown Course',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[800],
                        ),
                      ),
                      Text(
                        'by ${conflict['instructor']['name'] ?? 'Unknown Instructor'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                      if (conflict['start_time'] != null && conflict['end_time'] != null)
                        Text(
                          'Time: ${conflict['start_time']} - ${conflict['end_time']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      Text(
                        'Room: ${conflict['classroom']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvailableSlotsDialog(BuildContext context, List<Map<String, dynamic>> availableSlots, String classroom) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Available Time Slots for $classroom',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: availableSlots.map((slot) {
              final isAvailable = slot['available'] as bool;
              final startTime = slot['start_time'] as String;
              final endTime = slot['end_time'] as String;
              final conflictReason = slot['conflict_reason'] as String?;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable ? Colors.green[100]! : Colors.red[100]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            color: isAvailable ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAvailable ? 'Available' : 'Not Available',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isAvailable ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      if (!isAvailable && conflictReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reason: $conflictReason',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.red[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 