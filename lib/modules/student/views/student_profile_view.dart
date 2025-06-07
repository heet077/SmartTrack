import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_auth_controller.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<StudentAuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://picsum.photos/200', // Placeholder image
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'John Doe',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'CS2023001',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              _buildMenuItem(
                'Personal Information',
                Icons.person_outline,
                onTap: () {
                  // TODO: Navigate to personal information page
                },
              ),
              _buildMenuItem(
                'Change Password',
                Icons.lock_outline,
                onTap: () {
                  // TODO: Navigate to change password page
                },
              ),
              _buildMenuItem(
                'Notification Settings',
                Icons.notifications_none,
                onTap: () {
                  // TODO: Navigate to notification settings page
                },
              ),
              _buildMenuItem(
                'Help & Support',
                Icons.help_outline,
                onTap: () {
                  // TODO: Navigate to help & support page
                },
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                'Logout',
                Icons.logout,
                isDestructive: true,
                onTap: () => authController.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
    );
  }
} 