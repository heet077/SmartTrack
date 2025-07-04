import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/supabase_service.dart';

class DashboardController extends GetxController {
  final RxInt totalStudents = 0.obs;
  final RxInt totalInstructors = 0.obs;
  final RxInt totalCourses = 0.obs;
  final RxInt totalPrograms = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Fetch total students
      final studentsResponse = await SupabaseService.client
          .from('students')
          .select();
      totalStudents.value = (studentsResponse as List).length;

      // Fetch total instructors
      final instructorsResponse = await SupabaseService.client
          .from('instructors')
          .select();
      totalInstructors.value = (instructorsResponse as List).length;

      // Fetch total courses
      final coursesResponse = await SupabaseService.client
          .from('courses')
          .select();
      totalCourses.value = (coursesResponse as List).length;

      // Fetch total programs
      final programsResponse = await SupabaseService.client
          .from('programs')
          .select();
      totalPrograms.value = (programsResponse as List).length;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Navigation methods
  void navigateToManagePrograms() {
    Get.toNamed(AppRoutes.adminPrograms);
  }

  void navigateToManageCourses() {
    Get.toNamed(AppRoutes.adminCourses);
  }

  void navigateToManageInstructors() {
    Get.toNamed(AppRoutes.adminInstructors);
  }

  void navigateToManageStudents() {
    Get.toNamed(AppRoutes.adminStudents);
  }

  void navigateToAssignCourses() {
    Get.toNamed(AppRoutes.adminAssignCourses);
  }

  void navigateToViewAttendance() {
    Get.toNamed(AppRoutes.adminAttendance);
  }

  void navigateToSettings() {
    Get.toNamed(AppRoutes.adminSettings);
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }
} 