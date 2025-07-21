import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/main_layout_controller.dart';
import 'dashboard_view.dart';
import 'attendance_view.dart';
import 'profile_view.dart';
import 'admin_settings_view.dart';

class MainLayoutView extends GetView<MainLayoutController> {
  const MainLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DashboardView(),
      const AttendanceView(),
      const ProfileView(),
      const AdminSettingsView(),
    ];

    final List<String> titles = [
      'Dashboard',
      'Reports',
      'Profile',
      'Settings',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        toolbarHeight: 70,
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Panel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              titles[controller.currentIndex.value],
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            // child: IconButton(
            //   icon: const Icon(Icons.notifications_outlined),
            //   onPressed: () {
            //     // Handle notifications
            //   },
            // ),
          ),
        ],
      ),
      body: Obx(() => pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(() => NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 65,
        selectedIndex: controller.currentIndex.value,
        onDestinationSelected: controller.changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }
} 