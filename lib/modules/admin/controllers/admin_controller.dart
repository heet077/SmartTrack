import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AdminController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString selectedUserType = 'Admin'.obs;

  final List<String> userTypes = ['Admin', 'Professor'];

  void changeUserType(String? type) {
    if (type != null) {
      selectedUserType.value = type;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login(String email, String password) async {
    if (!_validateInputs()) return;
    
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      switch (selectedUserType.value) {
        case 'Admin':
          if (email == 'admin@admin.com' && password == 'admin123') {
            Get.offAllNamed('/admin/dashboard');
          } else {
            Get.snackbar(
              'Error',
              'Invalid admin credentials',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          break;
        case 'Professor':
          if (email == 'professor@test.com' && password == 'prof123') {
            Get.offAllNamed('/professor/dashboard');
          } else {
            Get.snackbar(
              'Error',
              'Invalid professor credentials',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          break;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to login',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  void logout() {
    // Clear text fields
    emailController.clear();
    passwordController.clear();
    
    // Reset state
    isLoading.value = false;
    isPasswordVisible.value = false;
    selectedUserType.value = 'Admin';
    
    // Navigate to login screen
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
} 