import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lecture_session_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/lecture_reschedule_controller.dart';
import '../models/lecture_session.dart';
import 'reschedule_lecture_dialog.dart';

class LectureView extends GetView<LectureSessionController> {
  const LectureView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          'Active Lecture',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: controller.endSession,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQrSection(),
              const SizedBox(height: 30),
              _buildAttendanceSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQrSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Attendance QR Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.isQrExpired.value) {
                return Column(
                  children: [
                    const Icon(
                      Icons.qr_code_2,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'QR Code Expired',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: controller.generateNewQrCode,
                      child: const Text('Generate New QR Code'),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  QrImageView(
                    data: controller.currentQrCode.value,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final remainingTime = controller.remainingTime.value;
                    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
                    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
                    return Text(
                      'Time Remaining: $minutes:$seconds',
                      style: const TextStyle(fontSize: 16),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Present Students',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.presentStudents.isEmpty) {
                return const Center(
                  child: Text('No students present yet'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.presentStudents.length,
                itemBuilder: (context, index) {
                  final student = controller.presentStudents[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(student.name[0].toUpperCase()),
                    ),
                    title: Text(student.name),
                    subtitle: Text(student.email),
                    trailing: Text(student.scanTime ?? ''),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureCard(LectureSession lecture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.courseCode,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        lecture.courseName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (lecture.isRescheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rescheduled',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lecture.startTime.hour}:${lecture.startTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(
                      Icons.room,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Room ${lecture.classroom}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!lecture.isRescheduled)
                  TextButton.icon(
                    onPressed: () {
                      final controller = Get.put(LectureRescheduleController());
                      Get.dialog(
                        RescheduleLectureDialog(
                          lecture: lecture,
                          controller: controller, lectureId: '',
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Reschedule',
                      style: GoogleFonts.poppins(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                if (lecture.isRescheduled)
                  TextButton.icon(
                    onPressed: () {
                      final controller = Get.find<LectureRescheduleController>();
                      controller.cancelRescheduling(lecture.rescheduleId!);
                    },
                    icon: const Icon(Icons.cancel),
                    label: Text(
                      'Cancel Reschedule',
                      style: GoogleFonts.poppins(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 