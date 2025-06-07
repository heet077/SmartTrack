import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'professor_dashboard_view.dart';
import 'my_courses_view.dart';
import 'attendance_list_view.dart';
import 'profile_view.dart';

class ProfessorMainLayout extends StatelessWidget {
  const ProfessorMainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;

    final List<Widget> pages = [
      const ProfessorDashboardView(),
      MyCoursesView(),
      const AttendanceListView(),
      const ProfileView(),
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
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
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