import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/passcode_controller.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceDetailView extends StatelessWidget {
  final String courseId;
  final String courseCode;

  const AttendanceDetailView({
    Key? key,
    required this.courseId,
    required this.courseCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AttendanceController>(tag: 'professor');
    final passcodeController = Get.find<PasscodeController>();

    // Preload the course data when the view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.preloadCourseData(courseId);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          courseCode,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: () {
              final controller = Get.find<AttendanceController>(tag: 'professor');
              controller.exportAttendanceToCSV(
                courseId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime(2024),
                lastDate: DateTime(2025, 12, 31),
              );
              if (date != null) {
                controller.changeDate(date);
              }
            },
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final attendanceData = controller.attendanceData[courseId];
        if (attendanceData == null) return const SizedBox.shrink();

        final records = List<Map<String, dynamic>>.from(attendanceData['records'] ?? []);
        final scannedStudents = records.where((r) => r['finalized'] != true).map((r) => r['student_id']).toList();
        
        if (scannedStudents.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () async {
            try {
              await passcodeController.generatePasscodes(
                courseId: courseId,
                studentIds: List<String>.from(scannedStudents),
                validityMinutes: 5,
              );
              Get.snackbar(
                'Success',
                'Passcodes sent to ${scannedStudents.length} students',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
              );
            } catch (e) {
              Get.snackbar(
                'Error',
                'Failed to send passcodes: ${e.toString()}',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          icon: const Icon(Icons.send),
          label: Text('Send Passcodes (${scannedStudents.length})'),
          backgroundColor: Colors.blue,
        );
      }),
      body: Obx(() {
        final attendanceData = controller.attendanceData[courseId];
        if (attendanceData == null) {
          return const Center(child: Text('No attendance data available'));
        }

        final records = List<Map<String, dynamic>>.from(attendanceData['records'] ?? []);
        final enrolledStudents = controller.getEnrolledStudents(courseId);
        
        return Column(
          children: [
            // Attendance Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(controller.selectedDate.value),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total',
                          attendanceData['total'].toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Present',
                          attendanceData['present'].toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Absent',
                          attendanceData['absent'].toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Status Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      attendanceData['status'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(attendanceData['status'].toString()),
                  ),
                  if (attendanceData['isVerified'])
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text(
                          'VERIFIED',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: enrolledStudents.length,
                itemBuilder: (context, index) {
                  final student = enrolledStudents[index];
                  final record = records.firstWhereOrNull(
                    (r) => r['student_id'] == student['id']
                  );
                  final hasScannedQR = record != null;
                  final isVerifiedWithOTP = record != null && record['finalized'] == true;
                  final attendanceStatus = isVerifiedWithOTP ? 'Verified' 
                      : hasScannedQR ? 'QR Scanned' 
                      : 'Absent';
                  final statusColor = isVerifiedWithOTP ? Colors.green 
                      : hasScannedQR ? Colors.orange 
                      : Colors.red;
                  final statusIcon = isVerifiedWithOTP ? Icons.verified 
                      : hasScannedQR ? Icons.qr_code_scanner 
                      : Icons.close;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor,
                        child: Icon(
                          statusIcon,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(student['name']),
                      subtitle: Text(student['enrollment_no'] ?? 'No enrollment number'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            attendanceStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasScannedQR && !isVerifiedWithOTP)
                            Text(
                              'Awaiting OTP',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
} 