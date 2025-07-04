import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({Key? key}) : super(key: key);

  // Define the primary color
  static const primaryColor = Color(0xFF2196F3); // Material Blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Management',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
       // backgroundColor: primaryColor,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadPrograms,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey[100],
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Download All Programs section
              if (controller.programs.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete Attendance Report',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Download attendance data for all programs and semesters',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: [
                            _buildActionButton(
                              onPressed: controller.exportAllProgramsAsCSV,
                              icon: Icons.file_download,
                              label: 'Download CSV',
                              color: primaryColor,
                            ),
                            _buildActionButton(
                              onPressed: controller.exportAllProgramsAsPDF,
                              icon: Icons.picture_as_pdf,
                              label: 'Download PDF',
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Program Selection section
              if (controller.programs.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Select Program',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Choose a Program',
                            labelStyle: GoogleFonts.poppins(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          value: controller.selectedProgram.value.isEmpty
                              ? null
                              : controller.selectedProgram.value,
                          items: controller.programs
                              .map((program) => DropdownMenuItem<String>(
                                    value: program['id'],
                                    child: Text(
                                      program['name'],
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (String? programId) {
                            if (programId != null) {
                              controller.selectedProgram.value = programId;
                              controller.loadSemesters(programId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Semesters section
              if (controller.semesters.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Select Semester',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: controller.semesters.map((semester) {
                            return ElevatedButton(
                              onPressed: () => controller.loadStudentAttendance(
                                  controller.selectedProgram.value, semester),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Semester $semester',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Attendance Data section
              if (controller.studentAttendance.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendance Overview',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Overall: ${controller.overallAttendancePercentage.value.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    _buildActionButton(
                                      onPressed: controller.exportAsCSV,
                                      icon: Icons.file_download,
                                      label: 'CSV',
                                      color: primaryColor,
                                      small: true,
                                    ),
                                    _buildActionButton(
                                      onPressed: controller.exportAsPDF,
                                      icon: Icons.picture_as_pdf,
                                      label: 'PDF',
                                      color: primaryColor,
                                      small: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[100],
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Student Name',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Enrollment No',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Attendance %',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          rows: controller.studentAttendance
                              .map(
                                (student) => DataRow(
                                  cells: [
                                    DataCell(Text(
                                      student['student_name'] ?? '',
                                      style: GoogleFonts.poppins(),
                                    )),
                                    DataCell(Text(
                                      student['enrollment_no'] ?? '',
                                      style: GoogleFonts.poppins(),
                                    )),
                                    DataCell(
                                      Text(
                                        '${(student['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          color: _getAttendanceColor(
                                            student['attendance_percentage'] ?? 0,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool small = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: small ? 18 : 24),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: small ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 16 : 20,
          vertical: small ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
} 