import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_controller.dart';
import '../controllers/student_attendance_history_controller.dart';
import '../../admin/models/course_model.dart';
import 'student_main_layout.dart';
import '../../../routes/app_routes.dart';
import 'student_passcode_view.dart';
import 'verify_attendance_view.dart';

class StudentDashboardView extends GetView<StudentController> {
  const StudentDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.hasError.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.errorMessage.value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  controller.hasError.value = false;
                  controller.errorMessage.value = '';
                  controller.loadStudentData();
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
      }

      final student = controller.currentStudent.value;
      if (student == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No student data found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.loadStudentData,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadStudentData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${student.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${student.programName ?? "No Program"} - Semester ${student.semester}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: Text(
                          student.name?.substring(0, 1).toUpperCase() ?? 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Lectures',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.todayLectures.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No lectures scheduled for today',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.todayLectures.length,
                        itemBuilder: (context, index) {
                          final lecture = controller.todayLectures[index];
                          return _buildLectureCard(
                            lecture['subject'],
                            lecture['room'],
                            lecture['professor'],
                            lecture['time'],
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Scan QR',
                            onTap: () => Get.toNamed('/student/scan-qr'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.vpn_key,
                            label: 'View Passcode',
                            onTap: () async {
                              final studentController = Get.find<StudentController>();
                              
                              // Get student's courses
                              final courses = await studentController.loadStudentCourses();

                              if (courses.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'No courses found',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Show course selection dialog
                              final selectedCourse = await Get.dialog<Course>(
                                AlertDialog(
                                  title: Text(
                                    'Select Course',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: courses.map((course) => 
                                        ListTile(
                                          title: Text(
                                            course.name,
                                            style: GoogleFonts.poppins(),
                                          ),
                                          subtitle: Text(
                                            course.code,
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          onTap: () {
                                            Get.back(result: course);
                                          },
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              );

                              if (selectedCourse != null) {
                                studentController.currentCourse.value = selectedCourse;
                                Get.to(() => StudentPasscodeView(
                                  courseId: selectedCourse.id,
                                  courseName: selectedCourse.name,
                                ));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.verified_user,
                            label: 'Verify Attendance',
                            onTap: () async {
                              final studentController = Get.find<StudentController>();
                              
                              // Get student's courses
                              final courses = await studentController.loadStudentCourses();

                              if (courses.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'No courses found',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Show course selection dialog
                              final selectedCourse = await Get.dialog<Course>(
                                AlertDialog(
                                  title: Text(
                                    'Select Course',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: courses.map((course) => 
                                        ListTile(
                                          title: Text(
                                            course.name,
                                            style: GoogleFonts.poppins(),
                                          ),
                                          subtitle: Text(
                                            course.code,
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          onTap: () {
                                            Get.back(result: course);
                                          },
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              );

                              if (selectedCourse != null) {
                                studentController.currentCourse.value = selectedCourse;
                                Get.to(() => VerifyAttendanceView(
                                  courseId: selectedCourse.id,
                                  courseName: selectedCourse.name,
                                ));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.history,
                            label: 'Attendance History',
                            onTap: () => Get.toNamed('/student/attendance-history'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Attendance Summary'),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (controller.hasError.value) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  controller.errorMessage.value,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.hasError.value = false;
                                    controller.errorMessage.value = '';
                                    controller.loadAttendanceStats();
                                  },
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (controller.courseAttendance.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'No attendance data available',
                                  style: GoogleFonts.poppins(),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => controller.loadAttendanceStats(),
                                  child: Text(
                                    'Refresh Data',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Calculate overall attendance
                      final overallAttendance = controller.courseAttendance.values.isNotEmpty
                          ? controller.courseAttendance.values.reduce((a, b) => a + b) /
                              controller.courseAttendance.length
                          : 0.0;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getAttendanceColor(overallAttendance),
                                        width: 8,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${overallAttendance.toStringAsFixed(1)}%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: _getAttendanceColor(overallAttendance),
                                              ),
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Overall',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: controller.courseAttendance.entries
                                          .map((entry) => _buildAttendanceBar(
                                                entry.key,
                                                entry.value / 100,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Switch to attendance tab using the static reference
                                    StudentMainLayout.currentIndex.value = 1;
                                  },
                                  icon: const Icon(Icons.bar_chart),
                                  label: Text(
                                    'View Full Attendance History',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
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
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLectureCard(
    String subject,
    String room,
    String professor,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.room, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: Text(
                  room,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  professor,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBar(String subject, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                subject,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 