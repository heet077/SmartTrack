import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/lecture_session_controller.dart';
import '../controllers/passcode_controller.dart';
import '../models/lecture_session.dart';
import 'manage_passcodes_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../admin/controllers/admin_settings_controller.dart';
import 'package:intl/intl.dart';

class QrAttendanceView extends GetView<LectureSessionController> {
  final String courseId;
  final String courseName;
  final String scheduleId;

  QrAttendanceView({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.scheduleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the session when view is created
    controller.initSession(courseId, scheduleId);
    final passcodeController = Get.find<PasscodeController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          'Attendance - $courseName',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.currentSession.value != null
                ? () => controller.endSession()
                : null,
            child: Text(
              'End Session',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.currentSession.value == null) {
          return Center(
            child: ElevatedButton(
                  onPressed: () => controller.startSession(courseId, scheduleId),
                  child: const Text('Start Session'),
            ),
          );
        }

        return Column(
          children: [
            // QR Code Section
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
          child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    // QR Code Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                  child: Column(
                        children: [
                          if (controller.currentQrCode.value.isNotEmpty)
                            QrImageView(
                            data: controller.currentQrCode.value,
                            version: QrVersions.auto,
                            size: 200.0,
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => controller.generateNewQrCode(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate New QR Code'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Present Students Counter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        final presentCount = controller.presentStudents.length;
                        final verifiedCount = controller.verifiedStudents.length;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Scanned',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                    ),
                                    ),
                                    Text(
                                      '$presentCount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                        ],
                      ),
                                const SizedBox(width: 48),
                                Column(
                          children: [
                            Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                                      '$verifiedCount',
                                      style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                        color: Colors.green,
                              ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                    ],
                  ),
                ),
              ),
            // Present Students List
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Students',
                          style: TextStyle(
                          fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                        ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (controller.presentStudents.isNotEmpty) {
                              Get.to(() => ManagePasscodesView(
                                courseId: courseId,
                                courseName: courseName,
                                scannedStudentIds: controller.presentStudents
                                    .map((s) => s.id)
                                    .toList(),
                              ));
                            }
                          },
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Manage Passcodes'),
                        ),
                      ],
                      ),
                      const SizedBox(height: 16),
                    Expanded(
                      child: Obx(() {
                        final allStudents = [...controller.presentStudents, ...controller.verifiedStudents];
                        
                        if (allStudents.isEmpty) {
                          return Center(
                            child: Text(
                              'No students have scanned the QR code yet',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: allStudents.length,
                          itemBuilder: (context, index) {
                            final student = allStudents[index];
                            final isVerified = controller.verifiedStudents.any((s) => s.id == student.id);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
                                  child: Icon(
                                    isVerified ? Icons.verified_user : Icons.qr_code_scanner,
                                    color: isVerified ? Colors.green : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  isVerified ? 'Verified' : 'Waiting for Passcode',
                                        style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isVerified ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                trailing: Text(
                                  DateFormat('HH:mm').format(DateTime.parse(student.scanTime!)),
                                        style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                        ),
                                      ),
                            );
                          },
                        );
                      }),
                                  ),
                                ],
                              ),
                              ),
                            ),
                          ],
                        );
                      }),
      bottomNavigationBar: Obx(() {
        if (controller.currentSession.value != null) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // End Session Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.endSession(),
                      icon: const Icon(Icons.stop),
                      label: Text(
                        'End Session',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                    ),
                      ),
                    ),
              ),
                  const SizedBox(width: 16),
                  // Send Passcodes Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.presentStudents.isNotEmpty
                        ? () {
                            // Show dialog to set passcode validity duration
                            Get.dialog(
                              AlertDialog(
                                title: Text(
                                  'Generate Passcodes',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Set validity duration for passcodes',
                                      style: GoogleFonts.poppins(),
                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: TextEditingController(text: '30'),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Duration (minutes)',
                                        labelStyle: GoogleFonts.poppins(),
                                        border: const OutlineInputBorder(),
                                      ),
                                      onSubmitted: (value) {
                                        final minutes = int.tryParse(value);
                                        if (minutes != null && minutes > 0) {
                                          Get.back(result: minutes);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final minutes = int.tryParse(
                                        Get.find<TextEditingController>().text,
                                      );
                                      if (minutes != null && minutes > 0) {
                                        Get.back(result: minutes);
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          'Please enter a valid duration',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Generate',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                              ),
                            ).then((validityMinutes) {
                              if (validityMinutes != null) {
                                final scannedStudentIds = controller.presentStudents
                                    .map((s) => s.id)
                                    .toList();

                                // Generate passcodes and show management view
                                Get.find<PasscodeController>().generatePasscodes(
                                  courseId: courseId,
                                  studentIds: scannedStudentIds,
                                  validityMinutes: validityMinutes,
                                ).then((_) {
                                  Get.to(() => ManagePasscodesView(
                                    courseId: courseId,
                                    courseName: courseName,
                                    scannedStudentIds: scannedStudentIds,
                                  ));
                                });
                              }
                            });
                          }
                        : null,
                      icon: const Icon(Icons.vpn_key),
                      label: Text(
                        'Send Passcodes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                      ),
                      ),
                    ),
                  ),
            ],
          ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp).toLocal();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 