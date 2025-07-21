import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_schedule_controller.dart';
import '../models/course_schedule_model.dart';

class CourseScheduleView extends GetView<CourseScheduleController> {
  const CourseScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Schedule',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search schedules...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final schedules = controller.filteredSchedules;
              if (schedules.isEmpty) {
                return Center(
                  child: Text(
                    'No schedules found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _buildScheduleCard(schedule);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleCard(CourseSchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.book_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${schedule.courseCode} - ${schedule.courseName}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(schedule);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.instructorName ?? 'No instructor assigned',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${schedule.dayName} ${schedule.startTime}-${schedule.endTime}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.classroom,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(CourseSchedule schedule) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Delete Schedule',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this schedule?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSchedule(schedule.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    final courseCodeController = TextEditingController();
    final courseNameController = TextEditingController();
    final instructorNameController = TextEditingController();
    final instructorIdController = TextEditingController();
    final roomController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final selectedDays = <String>[].obs;

    Get.dialog(
      AlertDialog(
        title: Text(
          'Add New Schedule',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructorNameController,
                decoration: const InputDecoration(
                  labelText: 'Instructor Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructorIdController,
                decoration: const InputDecoration(
                  labelText: 'Instructor ID',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        hintText: '10:00 AM',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        hintText: '11:00 AM',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Day',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: CourseSchedule.daysOfWeek.asMap().entries.map((entry) {
                      final index = entry.key;
                      final day = entry.value;
                      return Obx(() {
                        final isSelected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(
                            day,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              selectedDays.clear();  // Only allow one day
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          },
                        );
                      });
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (courseCodeController.text.isEmpty ||
                  courseNameController.text.isEmpty ||
                  instructorNameController.text.isEmpty ||
                  instructorIdController.text.isEmpty ||
                  roomController.text.isEmpty ||
                  startTimeController.text.isEmpty ||
                  endTimeController.text.isEmpty ||
                  selectedDays.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill in all fields',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final schedule = CourseSchedule(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                assignmentId: instructorIdController.text,
                classroom: roomController.text,
                dayOfWeek: CourseSchedule.daysOfWeek.indexOf(selectedDays.first) + 1,
                startTime: startTimeController.text,
                endTime: endTimeController.text,
                courseCode: courseCodeController.text,
                courseName: courseNameController.text,
                instructorName: instructorNameController.text,
              );

              // Check for conflicts
              final hasConflict = await controller.hasConflict(schedule);
              if (hasConflict) {
                Get.snackbar(
                  'Error',
                  'This schedule conflicts with an existing schedule',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              await controller.addSchedule(schedule);
              Get.back();
            },
            child: Text(
              'Add',
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