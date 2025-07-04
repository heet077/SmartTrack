import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthController extends GetxController {
  final _supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString selectedRole = 'Student'.obs;

  void setRole(String role) {
    selectedRole.value = role;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  bool _validateInputs() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (selectedRole.value != 'Student' && !GetUtils.isEmail(emailController.text)) {
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

  Future<void> _ensureSupabaseAuth(String email, String password) async {
    try {
      // Try to sign in first
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        // If sign in fails, try to sign up
        final signUpResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (signUpResponse.user == null) {
          throw Exception('Failed to authenticate with Supabase');
        }
      }
    } catch (e) {
      debugPrint('Supabase auth error: $e');
      // If both sign in and sign up fail, create a new account
      try {
        await _supabase.auth.signUp(
          email: email,
          password: password,
        );
      } catch (signUpError) {
        debugPrint('Final signup attempt error: $signUpError');
        // Even if this fails, we'll continue as the database auth was successful
      }
    }
  }

  Future<void> login(String username, String password) async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;
      
      switch (selectedRole.value) {
        case 'Student':
          final studentCheck = await _supabase
              .from('students')
              .select()
              .eq('email', username)
              .eq('password', password)
              .maybeSingle();

          if (studentCheck != null) {
            await _ensureSupabaseAuth(username, password);
            debugPrint('Student login successful with data: $studentCheck');
            Get.offAllNamed(AppRoutes.studentDashboard);
            return;
          }
          break;

        case 'Professor':
          final professorCheck = await _supabase
              .from('instructors')
              .select()
              .eq('email', username)
              .eq('password', password)
              .maybeSingle();

          if (professorCheck != null) {
            await _ensureSupabaseAuth(username, password);
            debugPrint('Professor login successful with data: $professorCheck');
            Get.offAllNamed(AppRoutes.professorDashboard);
            return;
          }
          break;

        case 'Admin':
          debugPrint('Attempting admin login with email: $username');
          
          // First check if admin exists without password check
          final adminExists = await _supabase
              .from('admins')
              .select()
              .eq('email', username.trim())
              .maybeSingle();
              
          if (adminExists != null) {
            debugPrint('Admin exists check: $adminExists');
            
            // Clean up passwords by removing whitespace and newlines
            final storedPassword = adminExists['password'].toString().trim().replaceAll(RegExp(r'\s'), '');
            final inputPassword = password.trim().replaceAll(RegExp(r'\s'), '');
            
            debugPrint('Cleaned stored password: "$storedPassword" (${storedPassword.length} chars)');
            debugPrint('Cleaned input password: "$inputPassword" (${inputPassword.length} chars)');
            
            // Try direct password comparison with cleaned passwords
            if (storedPassword == inputPassword) {
              debugPrint('Password match successful after cleaning');
              await _ensureSupabaseAuth(username, password);
              Get.offAllNamed(AppRoutes.adminDashboard);
              return;
            } else {
              debugPrint('Password comparison failed after cleaning');
              debugPrint('ASCII codes of cleaned stored password: ${storedPassword.codeUnits}');
              debugPrint('ASCII codes of cleaned input password: ${inputPassword.codeUnits}');
            }
          } else {
            debugPrint('No admin found with this email');
          }
          
          Get.snackbar(
            'Error',
            'Invalid credentials',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
      }

      Get.snackbar(
        'Error',
        'Invalid credentials',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Login error: $e');
      Get.snackbar(
        'Error',
        'Failed to login: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from Supabase
    await _supabase.auth.signOut();
      
      // Reset controller state
      isLoading.value = false;
      selectedRole.value = 'Student';
      isPasswordVisible.value = false;
      
      // Navigate to login screen
    Get.offAllNamed(AppRoutes.login);
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

  void _handleNavigation(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        Get.offAllNamed(AppRoutes.studentDashboard);
        break;
      case 'professor':
        Get.offAllNamed(AppRoutes.professorDashboard);
        break;
      case 'admin':
        Get.offAllNamed(AppRoutes.adminDashboard);
        break;
      default:
        Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
} 