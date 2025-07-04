import 'package:get/get.dart';
import '../../student/controllers/student_controller.dart';
import '../controllers/student_controller.dart';
import '../controllers/program_controller.dart';
import '../controllers/instructor_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // Use permanent bindings for controllers that need to persist
    Get.put(StudentController(), permanent: true);
    Get.put(ProgramController(), permanent: true);
    Get.put(InstructorController(), permanent: true);
  }
} 