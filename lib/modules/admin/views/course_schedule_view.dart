import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_schedule_controller.dart';
import '../models/course_schedule_model.dart';

class CourseScheduleView extends StatelessWidget {
  final CourseScheduleController controller = Get.find<CourseScheduleController>();

  CourseScheduleView({Key? key}) : super(key: key);

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
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Obx(() => DropdownButton<int>(
                        value: controller.selectedDay.value,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(
                              'All Days',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          ...List.generate(5, (index) => index + 1).map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text(
                                _getDayName(day),
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedDay.value = value;
                          }
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.error.value,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadSchedules,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final schedules = controller.filteredSchedules;
              if (schedules.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchQuery.value.isEmpty
                        ? 'No schedules found'
                        : 'No schedules match your search',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadSchedules,
                child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
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
                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        schedule.courseName ?? 'Unknown Course',
                    style: GoogleFonts.poppins(
                                          fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                                      const SizedBox(height: 4),
                Text(
                                        'Course Code: ${schedule.courseCode ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                                          color: Colors.grey[600],
                  ),
                ),
              ],
                  ),
                ),
              ],
            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
              children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                ),
                                    child: Text(
                                      _getDayName(schedule.dayOfWeek),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                  ),
                ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
          ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
            child: Text(
                                      '${schedule.startTime} - ${schedule.endTime}',
              style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
              ),
            ),
          ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      schedule.classroom,
          style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
                            ),
                            const SizedBox(height: 12),
                  Text(
                              'Instructor: ${schedule.instructorName}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                                color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      default: return 'Unknown';
    }
  }
} 