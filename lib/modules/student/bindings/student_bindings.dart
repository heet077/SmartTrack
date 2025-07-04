import 'package:get/get.dart';
import '../controllers/student_controller.dart';
import '../controllers/student_attendance_marking_controller.dart';
import '../controllers/student_attendance_history_controller.dart';

class StudentBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentController>(() => StudentController());
    Get.lazyPut<StudentAttendanceMarkingController>(() => StudentAttendanceMarkingController());
    Get.lazyPut<StudentAttendanceHistoryController>(() => StudentAttendanceHistoryController());
  }
} 