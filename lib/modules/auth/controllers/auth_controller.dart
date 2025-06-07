import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString selectedRole = 'Admin'.obs;  // Default to Admin
  final RxBool isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> signIn({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('Attempting login for $userType with username: $username');

      switch (userType) {
        case 'Student':
          debugPrint('Checking students table...');
          final studentData = await _supabase
              .from('students')
              .select()
              .eq('email', username)
              .single();
          
          if (studentData != null) {
            debugPrint('Student login successful with data: $studentData');
            Get.offAllNamed('/student/dashboard');
          } else {
            debugPrint('No matching student found');
            throw Exception('Invalid credentials');
          }
          break;

        case 'Professor':
          debugPrint('Checking instructors table...');
          
          try {
            // First check if the professor exists in instructors table
            final professorCheck = await _supabase
                .from('instructors')
                .select()
                .eq('email', username)
                .single();
            
            debugPrint('Professor check result: $professorCheck');
            
            if (professorCheck == null) {
              debugPrint('No matching professor found in instructors table');
              throw Exception('Professor not found');
            }

            // Check if the provided password matches the plain_password in database
            if (password == professorCheck['plain_password']) {
              debugPrint('Password matches database plain_password');
              
              try {
                // Try signing in with Supabase auth
                final authResponse = await _supabase.auth.signInWithPassword(
                  email: username,
                  password: password,
                );

                if (authResponse.user != null) {
                  debugPrint('Professor login successful with data: $professorCheck');
                  Get.offAllNamed(AppRoutes.professorDashboard);
                  return;
                }
              } catch (authError) {
                debugPrint('Auth error (trying to create account): $authError');
                
                // If auth fails, try to create account
                try {
                  final signUpResponse = await _supabase.auth.signUp(
                    email: username,
                    password: password,
                    emailRedirectTo: null, // Disable email verification
                  );

                  if (signUpResponse.user != null) {
                    debugPrint('Created new auth account successfully');
                    // Try signing in immediately since we disabled email verification
                    final authResponse = await _supabase.auth.signInWithPassword(
                      email: username,
                      password: password,
                    );

                    if (authResponse.user != null) {
                      debugPrint('Professor login successful after account creation');
                      Get.offAllNamed(AppRoutes.professorDashboard);
                      return;
                    }
                  }
                } catch (signUpError) {
                  debugPrint('SignUp error: $signUpError');
                }
              }
            }

            throw Exception('Authentication failed');
          } catch (e) {
            debugPrint('Professor authentication error: $e');
            Get.snackbar(
              'Error',
              e.toString().contains('Professor not found') 
                  ? 'Professor account not found' 
                  : 'Invalid credentials - Please use your email as password for first login',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
          break;

        case 'Admin':
          debugPrint('Checking admins table...');
          
          final hashedPassword = _hashPassword(password);
          debugPrint('Checking with hashed password: $hashedPassword');
          
          final adminData = await _supabase
              .from('admins')
              .select()
              .eq('email', username)
              .eq('password_hash', hashedPassword)
              .single();
          
          if (adminData != null) {
            debugPrint('Admin login successful with data: $adminData');
            Get.offAllNamed('/admin/dashboard');
          } else {
            debugPrint('No matching admin found');
            throw Exception('Invalid credentials');
          }
          break;

        default:
          throw Exception('Invalid role selected');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      Get.snackbar(
        'Error',
        'Invalid credentials',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
} 