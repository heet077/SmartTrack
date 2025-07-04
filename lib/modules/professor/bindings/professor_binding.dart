import 'package:get/get.dart';
import '../controllers/professor_auth_controller.dart';
import '../controllers/professor_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/passcode_controller.dart';
import '../controllers/lecture_session_controller.dart';

class ProfessorBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize ProfessorController as permanent
    if (!Get.isRegistered<ProfessorController>()) {
      Get.put(ProfessorController(), permanent: true);
    }
    
    // Initialize LectureSessionController with fenix
    Get.lazyPut(() => LectureSessionController(), fenix: true);
    
    // Initialize AttendanceController as permanent with tag
    if (!Get.isRegistered<AttendanceController>(tag: 'professor')) {
    Get.put(AttendanceController(), tag: 'professor', permanent: true);
    }

    // Initialize ProfessorAuthController
    Get.lazyPut(() => ProfessorAuthController());
    
    // Initialize PasscodeController as permanent
    if (!Get.isRegistered<PasscodeController>()) {
      Get.put(PasscodeController(), permanent: true);
    }
  }
} 