import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class AdminAuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Mock admin credentials (In real app, this would be in a secure database)
  final Map<String, String> _adminCredentials = {
    'admin@admin.com': 'admin123',
  };

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (email.isEmpty || password.isEmpty) {
        error.value = 'Please enter both email and password';
        return false;
      }

      debugPrint('Attempting admin login with email: $email');
      
      // First check if admin exists without password check
      final adminExists = await SupabaseService.client
          .from('admins')
          .select()
          .eq('email', email.trim())
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
          Get.offAllNamed('/admin/dashboard');
          return true;
        } else {
          debugPrint('Password comparison failed after cleaning');
          debugPrint('ASCII codes of cleaned stored password: ${storedPassword.codeUnits}');
          debugPrint('ASCII codes of cleaned input password: ${inputPassword.codeUnits}');
          error.value = 'Invalid password';
          return false;
        }
      } else {
        debugPrint('No admin found with this email');
        error.value = 'Invalid email';
        return false;
      }
    } catch (e) {
      debugPrint('Admin login error: $e');
      error.value = 'An error occurred: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    Get.offAllNamed('/login');
  }
} 