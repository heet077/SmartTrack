import 'package:get/get.dart';
import '../controllers/student_auth_controller.dart';
import '../controllers/student_attendance_marking_controller.dart';

class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StudentAuthController(), permanent: true);
    Get.lazyPut(() => StudentAttendanceMarkingController());
  }
} 