import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'student_dashboard_view.dart';
import 'student_attendance_view.dart';
import 'student_profile_view.dart';

class StudentMainLayout extends StatelessWidget {
  const StudentMainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;

    final List<Widget> pages = [
      const StudentDashboardView(),
      const StudentAttendanceView(),
      const StudentProfileView(),
    ];

    return Scaffold(
      body: Obx(() => pages[currentIndex.value]),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: currentIndex.value,
          onDestinationSelected: (index) => currentIndex.value = index,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} 