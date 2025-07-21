import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/passcode_controller.dart';
import 'manage_passcodes_view.dart';

class TakeAttendanceView extends StatelessWidget {
  final String courseId;
  final String courseName;

  const TakeAttendanceView({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.find<AttendanceController>();
    final passcodeController = Get.find<PasscodeController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          'Take Attendance - $courseName',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        if (attendanceController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (attendanceController.students.isEmpty) {
          return Center(
            child: Text(
              'No students found for this course',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        final presentStudents = attendanceController.students
            .where((s) => s.isPresent.value)
            .toList();
        final totalStudents = attendanceController.students.length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Students: $totalStudents',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Scanned: ${presentStudents.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (presentStudents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
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
                                (Get.find<TextEditingController>()).text,
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
                        final scannedStudentIds = presentStudents
                            .map((s) => s.id)
                            .toList();

                        // Generate passcodes and show management view
                        passcodeController.generatePasscodes(
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
                  },
                  icon: const Icon(Icons.vpn_key),
                  label: Text(
                    'Send Verification Passcodes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceController.students.length,
                itemBuilder: (context, index) {
                  final student = attendanceController.students[index];
                  return Obx(() => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: student.isPresent.value
                            ? Colors.green
                            : Colors.grey,
                        child: Text(
                          student.name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        student.enrollmentNo,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Switch(
                        value: student.isPresent.value,
                        onChanged: (value) {
                          attendanceController.markAttendance(
                            student.id,
                            courseId,
                            value,
                          );
                        },
                      ),
                    ),
                  ));
                },
              ),
            ),
          ],
        );
      }),
    );
  }
} 