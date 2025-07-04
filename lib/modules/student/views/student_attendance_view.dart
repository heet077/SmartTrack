import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_attendance_controller.dart';

class StudentAttendanceView extends GetView<StudentAttendanceController> {
  const StudentAttendanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Attendance Data'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.courseAttendances.isEmpty) {
          return const Center(child: Text('No attendance records'));
        }

        return ListView.separated(
          itemCount: controller.courseAttendances.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final attendance = controller.courseAttendances[index];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject: ${attendance.subject}'),
                  Text('Present: ${attendance.attended}'),
                  Text('Total: ${attendance.total}'),
                  Text('Percentage: ${(attendance.percentage * 100).toStringAsFixed(2)}%'),
                ],
              ),
            );
          },
        );
      }),
    );
  }
} 