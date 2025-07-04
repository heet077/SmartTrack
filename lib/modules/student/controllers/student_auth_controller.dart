import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/student_controller.dart';
import '../controllers/student_attendance_history_controller.dart';

class StudentAuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;

  Future<bool> login({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _authService.signIn(
        username: username,
        password: password,
        userType: userType,
      );

      if (response != null) {
        // Navigate to student dashboard
        Get.offAllNamed('/student/dashboard');
        return true;
      } else {
        error.value = 'Invalid roll number or password';
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _authService.signUp(
        email: email,
        password: password,
        userType: 'student',
        name: name,
      );

      if (response.user != null) {
        // Navigate to student dashboard
        Get.offAllNamed('/student/dashboard');
        return true;
      } else {
        error.value = 'Failed to create account';
        return false;
      }
    } on AuthException catch (e) {
      error.value = e.message;
      return false;
    } catch (e) {
      error.value = 'An error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Reset all student-related state
      Get.delete<StudentController>(force: true);
      Get.delete<StudentAttendanceHistoryController>(force: true);
      Get.delete<StudentAuthController>(force: true);
      
      // Navigate to login screen
      Get.offAllNamed('/login');
      
    } catch (e) {
      debugPrint('Error during logout: $e');
      Get.snackbar(
        'Error',
        'Failed to logout properly',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 