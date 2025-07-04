import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/professor_controller.dart';
import '../controllers/lecture_session_controller.dart';
import '../controllers/passcode_controller.dart';
import '../controllers/attendance_controller.dart';
import '../models/lecture_session.dart';
import 'manage_passcodes_view.dart';
import 'package:intl/intl.dart';
import '../models/assigned_course.dart' as course_model;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class StartLectureView extends GetView<ProfessorController> {
  final lectureController = Get.find<LectureSessionController>();
  final passcodeController = Get.find<PasscodeController>();
  final attendanceController = Get.find<AttendanceController>(tag: 'professor');
  
  StartLectureView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.stopQrSession();
            Get.back();
          },
        ),
        title: Text(
          'Start Lecture',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.selectedCourseId.value.isEmpty) {
          // Show list of courses when no course is selected
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.assignedCourses.length,
            itemBuilder: (context, index) {
              final course = controller.assignedCourses[index];
              return FutureBuilder<bool>(
                future: Future.wait([
                  controller.hasLectureToday(course.courseId),
                  controller.hasAttendanceToday(course.courseId),
                ]).then((results) => results[0] && !results[1]),
                builder: (context, snapshot) {
                  final bool canStartLecture = snapshot.data ?? false;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.course.code,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.course.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.classroom,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${course.startTime} - ${course.endTime}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                course.dayName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!canStartLecture)
                                Text(
                                  snapshot.hasData ? 
                                    'No lecture scheduled for now' : 
                                    'Checking schedule...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    controller.selectedCourseId.value = course.courseId;
                                    await lectureController.startSession(
                                      course.courseId,
                                      course.id,
                                    );
                                    await attendanceController.loadStudentsForCourse(course.courseId);
                                    controller.startQrSession();
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Lecture'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        // Show QR code view when a course is selected
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Session Started',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Have students scan this QR code to mark attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Obx(() {
                          if (controller.isQrExpired.value) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: _generateQrData(),
                                  version: QrVersions.auto,
                                  size: 220.0,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Colors.grey,
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Colors.grey,
                                  ),
                                ),
                                Container(
                                  width: 220.0,
                                  height: 220.0,
                                  color: Colors.white.withOpacity(0.9),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.timer_off,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'QR Code Expired',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: controller.generateNewQrCode,
                                        child: Text(
                                          'Generate New QR',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return QrImageView(
                            data: _generateQrData(),
                            version: QrVersions.auto,
                            size: 220.0,
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isQrExpired.value) {
                          return Text(
                            'QR Code has expired',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          );
                        }
                        return Text(
                          'Valid for: ${_formatTimeRemaining()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Course Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                controller.selectedCourse.value?.course.code ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Start Time',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat('hh:mm a').format(DateTime.now()),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Students Present',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Obx(() => Text(
                                '${lectureController.presentStudents.length}/${attendanceController.students.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              )),
                            ],
                          ),
                          Obx(() => lectureController.presentStudents.isNotEmpty
                            ? ElevatedButton.icon(
                                onPressed: () {
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
                                      final scannedStudentIds = lectureController.presentStudents
                                          .map((s) => s.id)
                                          .toList();

                                      // Generate passcodes and show management view
                                      passcodeController.generatePasscodes(
                                        courseId: controller.selectedCourseId.value,
                                        studentIds: scannedStudentIds,
                                        validityMinutes: validityMinutes,
                                      ).then((_) {
                                        Get.to(() => ManagePasscodesView(
                                          courseId: controller.selectedCourseId.value,
                                          courseName: controller.selectedCourse.value?.course.code ?? '',
                                          scannedStudentIds: scannedStudentIds,
                                        ));
                                      });
                                    }
                                  });
                                },
                                icon: const Icon(Icons.vpn_key),
                                label: Text(
                                  'Send Verification Passcodes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.selectedCourseId.value.isNotEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  controller.stopQrSession();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'End Lecture',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  String _generateQrData() {
    final data = {
      'session_id': lectureController.currentSession.value?.id ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'valid_until': controller.qrExpiryTime.value.millisecondsSinceEpoch
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  String _formatTimeRemaining() {
    final remaining = controller.qrExpiryTime.value.difference(DateTime.now());
    return '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }
} 