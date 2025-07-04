import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      appBar: AppBar(
        title: Obx(() => Text(titles[controller.currentIndex.value])),
      ),
      body: Obx(() => pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(() => NavigationBar(
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