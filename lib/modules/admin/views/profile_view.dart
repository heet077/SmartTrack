import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_profile_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminProfileController());

    return RefreshIndicator(
      onRefresh: () => controller.refreshProfile(),
      child: Obx(() {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    controller.error.value,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                Text(
                  controller.adminData.value['name'] ?? 'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.adminData.value['email'] ?? 'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              _buildSection(
                title: 'Admin Management',
                items: [
                  _MenuItem(
                    icon: Icons.school,
                    title: 'Manage Programs',
                    onTap: () => Get.toNamed('/admin/dashboard/programs'),
                  ),
                  _MenuItem(
                    icon: Icons.book,
                    title: 'Manage Courses',
                    onTap: () => Get.toNamed('/admin/dashboard/courses'),
                  ),
                  _MenuItem(
                    icon: Icons.people,
                    title: 'Manage Students',
                    onTap: () => Get.toNamed('/admin/dashboard/students'),
                  ),
                  _MenuItem(
                    icon: Icons.person,
                    title: 'Manage Professors',
                    onTap: () => Get.toNamed('/admin/dashboard/instructors'),
                  ),
                ],
              ),
              const Divider(),
              _buildSection(
                title: 'Attendance Overview',
                items: [
                  _MenuItem(
                    icon: Icons.qr_code_scanner,
                    title: 'View Attendance Records',
                    onTap: () => Get.toNamed('/admin/dashboard/attendance'),
                  ),
                  _MenuItem(
                    icon: Icons.analytics,
                    title: 'Attendance Analytics',
                    onTap: () => Get.toNamed('/admin/dashboard/analytics'),
                  ),
                ],
              ),
              const Divider(),
              _buildSection(
                title: 'Account Settings',
                items: [
                  _MenuItem(
                    icon: Icons.security_outlined,
                    title: 'Security Settings',
                    onTap: () => Get.toNamed('/admin/dashboard/security'),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Get.toNamed('/admin/dashboard/support'),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => ListTile(
          leading: Icon(item.icon, color: Colors.blue),
          title: Text(
            item.title,
            style: GoogleFonts.poppins(),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: item.onTap,
        )),
      ],
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