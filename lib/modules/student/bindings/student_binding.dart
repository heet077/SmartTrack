import 'package:get/get.dart';
import '../controllers/student_auth_controller.dart';
import '../controllers/student_attendance_controller.dart';
import '../controllers/student_attendance_marking_controller.dart';
import '../controllers/student_controller.dart';
import '../../professor/controllers/passcode_controller.dart';

class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StudentAuthController());
    Get.put(StudentController());
    Get.put(StudentAttendanceController());
    Get.lazyPut(() => StudentAttendanceMarkingController());
    Get.put(PasscodeController());
    
    // Ensure StudentController is initialized immediately and kept in memory
    if (!Get.isRegistered<StudentController>()) {
      Get.put(StudentController(), permanent: true);
    }
  }
} 