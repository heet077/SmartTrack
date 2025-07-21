import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lecture_session_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
} 