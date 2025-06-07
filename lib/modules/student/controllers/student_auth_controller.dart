import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';

class StudentAuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final AuthService _authService = AuthService();

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

  void logout() {
    _authService.signOut();
  }
} 