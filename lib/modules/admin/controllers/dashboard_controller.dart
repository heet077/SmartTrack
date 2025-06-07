import 'package:get/get.dart';

class DashboardController extends GetxController {
  final RxInt totalStudents = 150.obs;
  final RxInt totalInstructors = 25.obs;
  final RxInt totalCourses = 45.obs;
  final RxInt ongoingLectures = 8.obs;

  // TODO: Replace with actual API calls
  Future<void> loadDashboardData() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      // In a real app, you would fetch these values from your backend
      totalStudents.value = 150;
      totalInstructors.value = 25;
      totalCourses.value = 45;
      ongoingLectures.value = 8;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToManagePrograms() {
    Get.toNamed('/admin/dashboard/programs');
  }

  void navigateToManageCourses() {
    Get.toNamed('/admin/dashboard/courses');
  }

  void navigateToManageInstructors() {
    Get.toNamed('/admin/dashboard/instructors');
  }

  void navigateToManageStudents() {
    Get.toNamed('/admin/dashboard/students');
  }

  void navigateToAssignCourses() {
    Get.toNamed('/admin/dashboard/assign-courses');
  }

  void navigateToViewAttendance() {
    Get.toNamed('/admin/dashboard/attendance');
  }

  void navigateToSettings() {
    Get.toNamed('/admin/dashboard/settings');
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }
} 