import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'student_dashboard_view.dart';
import 'student_attendance_history_view.dart';
import 'student_profile_view.dart';
import '../controllers/student_controller.dart';
import '../controllers/student_attendance_history_controller.dart';

class StudentMainLayout extends StatefulWidget {
  const StudentMainLayout({Key? key}) : super(key: key);

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  static final RxInt currentIndex = 0.obs;
  final studentController = Get.find<StudentController>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers here instead of in build
    Get.put(StudentAttendanceHistoryController());
    if (!Get.isRegistered<RxInt>(tag: 'bottomNavIndex')) {
      Get.put(currentIndex, tag: 'bottomNavIndex', permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('StudentMainLayout build called');

    final List<Widget> pages = [
      const StudentDashboardView(),
      const StudentAttendanceHistoryView(),
      const StudentProfileView(),
    ];

    return Scaffold(
      body: Obx(() {
        debugPrint('Current student: ${studentController.currentStudent.value?.name}');
        return IndexedStack(
          index: currentIndex.value,
          children: pages,
        );
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: currentIndex.value,
          onTap: (index) => currentIndex.value = index,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Attendance',
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
              backgroundColor: Colors.white,
            ),
          ],
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
} 