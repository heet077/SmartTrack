import 'package:get/get.dart';

class AuthController extends GetxController {
  void _handleLoginSuccess(Map<String, dynamic> userData) {
    final userType = userData['user_type']?.toString().toLowerCase();
    
    switch (userType) {
      case 'student':
        Get.offAllNamed('/student/dashboard');
        break;
      case 'professor':
        Get.offAllNamed('/professor/dashboard');
        break;
      case 'admin':
        Get.offAllNamed('/admin/dashboard');
        break;
      default:
        Get.snackbar(
          'Error',
          'Invalid user type',
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }
} 