import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lecture_session_controller.dart';
import '../models/lecture_session.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../admin/controllers/admin_settings_controller.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - $courseName'),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.currentSession.value != null
                    ? () => controller.endSession()
                    : null,
                child: const Text(
                  'End Session',
                  style: TextStyle(color: Colors.white),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final session = controller.currentSession.value;
        if (session == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show QR validity duration from admin settings
                Text(
                  'QR Code Validity: ${(controller.qrValidityDuration.value / 60).round()} minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.startSession(courseId, scheduleId),
                  child: const Text('Start Session'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // QR code display with reactivity
                          Obx(() => QrImageView(
                            data: controller.currentQrCode.value,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          )),
                          // Expiration overlay
                          Obx(() {
                            if (!controller.isQrExpired.value) return const SizedBox.shrink();
                            return Container(
                              width: 200.0,
                              height: 200.0,
                              color: Colors.white.withOpacity(0.8),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_off,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'QR Code Expired',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => controller.generateNewQrCode(),
                                      child: Text('Generate New QR'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final remainingTime = controller.remainingTime.value;
                        final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
                        final seconds = (remainingTime % 60).toString().padLeft(2, '0');
                        
                        return Column(
                          children: [
                            // Show QR validity duration from admin settings
                            Text(
                              'QR Code Validity: ${(controller.qrValidityDuration.value / 60).round()} minutes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$minutes:$seconds',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: remainingTime < 30 ? Colors.red : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: remainingTime / controller.qrValidityDuration.value,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remainingTime < 30 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      Text(
                        'Session ID: ${session.id}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Started at: ${session.startTime.toString().substring(11, 16)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Present Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Obx(() => Text(
                    '${controller.presentStudents.length} present',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.presentStudents.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No students present yet'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.presentStudents.length,
                  itemBuilder: (context, index) {
                    final student = controller.presentStudents[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student.name[0].toUpperCase()),
                        ),
                        title: Text(student.name),
                        subtitle: Text(student.email),
                        trailing: Text(
                          student.scanTime?.substring(11, 16) ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      }),
    );
  }
} 