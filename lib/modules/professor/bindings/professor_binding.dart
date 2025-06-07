import 'package:get/get.dart';
import '../controllers/professor_controller.dart';
import '../controllers/attendance_controller.dart' as professor;
import '../controllers/lecture_session_controller.dart';

class ProfessorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfessorController());
    Get.lazyPut(() => LectureSessionController(), fenix: true);
    Get.put<professor.AttendanceController>(professor.AttendanceController(), tag: 'professor');
  }
} 