import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/attendance_controller.dart';
import '../views/attendance_detail_view.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AttendanceController>(tag: 'professor');
    
    // Force refresh data when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Refreshing attendance data');
      controller.loadProfessorCourses();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Attendance',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: () {
              final selectedCourse = controller.courses.isNotEmpty ? controller.courses[0] : null;
              if (selectedCourse != null) {
                controller.exportAttendanceToCSV(
                  selectedCourse['id'],
                );
              } else {
                Get.snackbar(
                  'Error',
                  'No course selected',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              debugPrint('Manual refresh triggered');
              controller.loadProfessorCourses();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar Widget
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() {
                final selectedDate = controller.selectedDate.value;
                return TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: selectedDate,
                  currentDay: DateTime.now(),
                  selectedDayPredicate: (day) => 
                    isSameDay(selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    controller.changeDate(selectedDay);
                  },
                  onPageChanged: (focusedDay) {
                    controller.loadMonthAttendance(
                      controller.courses.isNotEmpty ? controller.courses[0]['id'] : '',
                      focusedDay,
                    );
                  },
                  calendarFormat: CalendarFormat.week,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronMargin: const EdgeInsets.all(0),
                    rightChevronMargin: const EdgeInsets.all(0),
                    headerMargin: const EdgeInsets.only(bottom: 4),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 12),
                    weekendStyle: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: const TextStyle(color: Colors.red, fontSize: 12),
                    holidayTextStyle: const TextStyle(color: Colors.red, fontSize: 12),
                    defaultTextStyle: const TextStyle(fontSize: 12),
                    selectedTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    todayTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    cellMargin: const EdgeInsets.all(4),
                  ),
                  eventLoader: (day) {
                    return controller.datesWithAttendance.contains(day) ? [true] : [];
                  },
                );
              }),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),

            // Selected Date Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() => Text(
                'Attendance for ${controller.selectedDate.value.toString().split(' ')[0]}',
                        style: GoogleFonts.poppins(
                  fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
              )),
            ),

            // Course List
            Obx(() {
              debugPrint('Rebuilding course list. Loading: ${controller.isLoading.value}');
              debugPrint('Number of courses: ${controller.courses.length}');
              debugPrint('Attendance data: ${controller.attendanceData}');

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.courses.isEmpty) {
                return Center(
                  child: Text(
                    'No courses assigned',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.courses.length,
                itemBuilder: (context, index) {
                  final course = controller.courses[index];
                  debugPrint('Building card for course: ${course['code']}');
                  
                  final attendance = controller.attendanceData[course['id']] ?? {};
                  debugPrint('Attendance data for course: $attendance');
                  
                  final total = attendance['total'] ?? 0;
                  final scannedQR = (attendance['records'] ?? []).length;
                  final verifiedOTP = (attendance['records'] ?? [])
                      .where((r) => r['finalized'] == true).length;
                  final absent = total - scannedQR;
                  final isVerified = attendance['isVerified'] ?? false;
                  final isScheduledDay = attendance['isScheduledDay'] ?? false;
                  final status = attendance['status'] ?? 'no_class';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // Ensure the controller is available in the detail view
                        Get.to(
                          () => AttendanceDetailView(
                            courseId: course['id'],
                            courseCode: course['code'],
                          ),
                          binding: BindingsBuilder(() {
                            // Use the existing controller instance
                            Get.put(controller, tag: 'professor');
                          }),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['code'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        course['name'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn('Total', total, Colors.blue),
                                    _buildStatColumn(
                                      'QR Scanned', 
                                      scannedQR, 
                                      Colors.orange,
                                    ),
                                    _buildStatColumn(
                                      'Verified', 
                                      verifiedOTP, 
                                      Colors.green,
                                    ),
                                    _buildStatColumn(
                                      'Absent', 
                                      absent, 
                                      Colors.red,
                                    ),
                                  ],
                                ),
                                if (scannedQR > 0 && scannedQR > verifiedOTP)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${scannedQR - verifiedOTP} students awaiting OTP verification',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      case 'no_class':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      case 'scheduled':
        return Icons.schedule;
      case 'no_class':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
} 