import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'professor_dashboard_view.dart';
import 'my_courses_view.dart';
import 'attendance_view.dart';
import 'profile_view.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/professor_controller.dart';

class ProfessorMainLayout extends StatelessWidget {
  const ProfessorMainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;

    // Initialize required controllers
    if (!Get.isRegistered<ProfessorController>()) {
      Get.put(ProfessorController(), permanent: true);
    }
    
    // Initialize AttendanceController with the correct tag
    if (!Get.isRegistered<AttendanceController>(tag: 'professor')) {
      Get.put(AttendanceController(), tag: 'professor', permanent: true);
    }

    final List<Widget> pages = [
      const ProfessorDashboardView(),
      MyCoursesView(),
      const AttendanceView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: Obx(() => pages[currentIndex.value]),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: currentIndex.value,
          onDestinationSelected: (index) {
            currentIndex.value = index;
            // Refresh attendance data when navigating to attendance page
            if (index == 2) {
              final attendanceController = Get.find<AttendanceController>(tag: 'professor');
              attendanceController.loadProfessorCourses();
            }
          },
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