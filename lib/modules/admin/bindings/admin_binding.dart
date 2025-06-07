import 'package:get/get.dart';
import '../controllers/admin_profile_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/program_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/main_layout_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/instructor_controller.dart';
import '../controllers/student_controller.dart';
import '../controllers/course_schedule_controller.dart';
import '../controllers/course_assignment_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/admin_settings_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers that should be available immediately and persist
    Get.put(MainLayoutController(), permanent: true);
    Get.put(AdminProfileController(), permanent: true);
    Get.put(StudentController(), permanent: true);
    Get.put(ProgramController(), permanent: true);
    Get.put(CourseController(), permanent: true);
    Get.put(InstructorController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(CourseAssignmentController(), permanent: true);

    // Controllers that can be lazy loaded
    Get.lazyPut(() => DashboardController());
    Get.lazyPut(() => SettingsController());
    Get.lazyPut(() => CourseScheduleController());
    Get.lazyPut(() => AdminController());
    Get.lazyPut(() => AdminSettingsController());
  }
} 