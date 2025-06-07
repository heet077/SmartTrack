import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

      // Get admin from the admins table
      final admin = await SupabaseService.getAdminByEmail(email);
      
      if (admin == null) {
        error.value = 'Invalid email or password';
        return false;
      }

      // Hash the provided password and compare with stored hash
      final hashedPassword = _hashPassword(password);
      if (hashedPassword != admin['password_hash']) {
        error.value = 'Invalid email or password';
        return false;
      }

      // Store admin info in local storage or GetX state management
      // You might want to store the admin ID and other relevant info
      Get.offAllNamed('/admin/dashboard');
      return true;
    } catch (e) {
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