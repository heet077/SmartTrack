import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/admin/controllers/admin_controller.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/professor/controllers/professor_controller.dart';
import '../../modules/professor/controllers/lecture_session_controller.dart';
import '../../modules/student/controllers/student_auth_controller.dart';
import '../../modules/admin/controllers/admin_settings_controller.dart';
import '../../modules/professor/controllers/passcode_controller.dart';
import '../../modules/student/controllers/student_passcode_controller.dart';
import '../../modules/student/controllers/student_controller.dart';
import '../../modules/student/controllers/student_attendance_marking_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    try {
      // Initialize only the critical auth controller immediately
      if (!Get.isRegistered<AuthController>()) {
        Get.put(AuthController(), permanent: true);
      }

      // Lazy load all other controllers
      Get.lazyPut(() => AdminSettingsController(), fenix: true);
      Get.lazyPut(() => PasscodeController(), fenix: true);
      Get.lazyPut(() => StudentPasscodeController(), fenix: true);
    Get.lazyPut(() => AdminController());
    Get.lazyPut(() => StudentAuthController());
    Get.lazyPut(() => ProfessorController());
    Get.lazyPut(() => LectureSessionController(), fenix: true);
      Get.lazyPut(() => StudentController());
      Get.lazyPut(() => StudentAttendanceMarkingController());
    } catch (e, stackTrace) {
      debugPrint('Error during controller initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
} 