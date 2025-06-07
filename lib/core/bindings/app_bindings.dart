import 'package:get/get.dart';
import '../../modules/admin/controllers/admin_controller.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/professor/controllers/professor_controller.dart';
import '../../modules/professor/controllers/lecture_session_controller.dart';
import '../../modules/student/controllers/student_auth_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => AdminController());
    Get.lazyPut(() => StudentAuthController());
    Get.lazyPut(() => ProfessorController());
    Get.lazyPut(() => LectureSessionController(), fenix: true);
  }
} 