import 'package:get/get.dart';
import '../../../services/admin_service.dart';

class AdminUsersController extends GetxController {
  final AdminService _adminService = AdminService();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> professors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Load both students and professors
      final studentsList = await _adminService.getStudents();
      final professorsList = await _adminService.getProfessors();

      students.value = studentsList;
      professors.value = professorsList;
    } catch (e) {
      error.value = 'Failed to load users';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String userType,
    required String rollNo,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final success = await _adminService.createUser(
        email: email,
        password: password,
        userType: userType,
        name: name,
        rollNo: rollNo,
      );

      if (success) {
        // Reload users to show the new user
        await loadUsers();
        Get.snackbar(
          'Success',
          'User created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        error.value = 'Failed to create user';
        Get.snackbar(
          'Error',
          'Failed to create user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      error.value = 'An error occurred';
      Get.snackbar(
        'Error',
        'An error occurred while creating user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final success = await _adminService.resetPassword(
        userId: userId,
        newPassword: newPassword,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Password reset successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        error.value = 'Failed to reset password';
        Get.snackbar(
          'Error',
          'Failed to reset password',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      error.value = 'An error occurred';
      Get.snackbar(
        'Error',
        'An error occurred while resetting password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final success = await _adminService.deleteUser(userId);

      if (success) {
        // Reload users to reflect the deletion
        await loadUsers();
        Get.snackbar(
          'Success',
          'User deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        error.value = 'Failed to delete user';
        Get.snackbar(
          'Error',
          'Failed to delete user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      error.value = 'An error occurred';
      Get.snackbar(
        'Error',
        'An error occurred while deleting user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 