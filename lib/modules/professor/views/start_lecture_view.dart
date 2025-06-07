import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/professor_controller.dart';
import '../controllers/lecture_session_controller.dart';
import '../models/lecture_session.dart';
import 'qr_attendance_view.dart';
import 'package:intl/intl.dart';
import '../models/assigned_course.dart' as course_model;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class StartLectureView extends GetView<ProfessorController> {
  final lectureController = Get.find<LectureSessionController>();
  
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
        title: const Text('Start Lecture'),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    controller.selectedCourseId.value = course.courseId;
                    await lectureController.startSession(
                      course.courseId,
                      course.id,
                    );
                    controller.startQrSession();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.course.code,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                course.course.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              course.classroom,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${course.startTime} - ${course.endTime}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                controller.selectedCourseId.value = course.courseId;
                                await lectureController.startSession(
                                  course.courseId,
                                  course.id,
                                );
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
                ),
              );
            },
          );
        }

        // Show QR code view when a course is selected
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Obx(() {
                        if (controller.isQrExpired.value) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _generateQrData(),
                                version: QrVersions.auto,
                                size: 200.0,
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
                                width: 200.0,
                                height: 200.0,
                                color: Colors.white.withOpacity(0.8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.timer_off,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'QR Code Expired',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: controller.generateNewQrCode,
                                      child: const Text('Generate New QR'),
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
                          size: 200.0,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isQrExpired.value) {
                        return const Text(
                          'QR Code has expired',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        );
                      }
                      return Text(
                        'Valid for: ${_formatTimeRemaining()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                    const Text(
                      'Have students scan this QR code to mark attendance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Course',
                      controller.getSelectedCourse()?.course.code ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Start Time',
                      DateFormat('hh:mm a').format(DateTime.now()),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => _buildInfoRow(
                      'Students Present',
                      '${lectureController.presentStudents.length}/45',
                    )),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await lectureController.endSession();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'End Lecture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatTimeRemaining() {
    final minutes = controller.remainingSeconds.value ~/ 60;
    final seconds = controller.remainingSeconds.value % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  String _generateQrData() {
    final selectedCourse = controller.getSelectedCourse();
    final session = lectureController.currentSession.value;
    if (selectedCourse == null || session == null) return '';

    // Use the current QR code if it exists and is not expired
    if (lectureController.currentQrCode.value.isNotEmpty && !lectureController.isQrExpired.value) {
      return lectureController.currentQrCode.value;
    }

    final data = {
      'session_id': session.id,
      'course_id': session.courseId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'valid_until': DateTime.now().add(Duration(seconds: controller.remainingSeconds.value)).millisecondsSinceEpoch,
    };
    return base64Encode(utf8.encode(json.encode(data)));
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 