import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_auth_controller.dart';
import '../controllers/student_controller.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<StudentAuthController>();
    final studentController = Get.find<StudentController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      final student = studentController.currentStudent.value;
                      if (student == null) return const SizedBox();

                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Text(
                              student.name?.substring(0, 1).toUpperCase() ?? 'S',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            student.name ?? 'No Name',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.registrationNumber ?? 'Not assigned',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Academic Information
              Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  final student = studentController.currentStudent.value;
                  if (student == null) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Academic Information'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow('Program', student.programName ?? 'Not assigned'),
                              const Divider(),
                              _buildInfoRow('Semester', student.semester.toString()),
                              const Divider(),
                              _buildInfoRow('Enrollment No', student.registrationNumber ?? 'Not assigned'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Contact Information'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildInfoRow('Email', student.email),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Account Settings'),
                      _buildMenuItem(
                        'Change Password',
                        Icons.lock_outline,
                        onTap: () {
                          // TODO: Implement change password
                          Get.snackbar(
                            'Coming Soon',
                            'Password change functionality will be available soon',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildMenuItem(
                        'Notification Settings',
                        Icons.notifications_none,
                        onTap: () {
                          // TODO: Implement notification settings
                          Get.snackbar(
                            'Coming Soon',
                            'Notification settings will be available soon',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildMenuItem(
                        'Help & Support',
                        Icons.help_outline,
                        onTap: () {
                          // TODO: Implement help & support
                          Get.snackbar(
                            'Coming Soon',
                            'Help & support will be available soon',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        'Logout',
                        Icons.logout,
                        isDestructive: true,
                        onTap: () => authController.logout(),
                      ),
                      const SizedBox(height: 24),

                      // App Information
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Attendance System',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive ? Colors.red : Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDestructive ? Colors.red : Colors.grey[800],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDestructive ? Colors.red : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 