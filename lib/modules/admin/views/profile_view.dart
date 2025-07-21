import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_profile_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminProfileController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => controller.refreshProfile(),
        child: Obx(() {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          if (controller.isLoading.value)
                            const Positioned.fill(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (controller.error.value.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[900], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.error.value,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red[900],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        controller.adminData.value['name'] ?? 'Loading...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.adminData.value['email'] ?? 'Loading...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildSection(
                        title: 'Admin Management',
                        items: [
                          _MenuItem(
                            icon: Icons.school_rounded,
                            title: 'Manage Programs',
                            onTap: () => Get.toNamed(AppRoutes.adminPrograms),
                          ),
                          _MenuItem(
                            icon: Icons.book_rounded,
                            title: 'Manage Courses',
                            onTap: () => Get.toNamed(AppRoutes.adminCourses),
                          ),
                          _MenuItem(
                            icon: Icons.people_rounded,
                            title: 'Manage Students',
                            onTap: () => Get.toNamed(AppRoutes.adminStudents),
                          ),
                          _MenuItem(
                            icon: Icons.person_rounded,
                            title: 'Manage Professors',
                            onTap: () => Get.toNamed(AppRoutes.adminInstructors),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Attendance Overview',
                        items: [
                          _MenuItem(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'View Attendance Records',
                            onTap: () => Get.toNamed(AppRoutes.adminAttendance),
                          ),
                          _MenuItem(
                            icon: Icons.analytics_rounded,
                            title: 'Attendance Analytics',
                            onTap: () => Get.toNamed('${AppRoutes.adminDashboard}/analytics'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.offAllNamed('/login'),
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...items.map((item) => InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
} 