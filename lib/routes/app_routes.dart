import 'package:get/get.dart';
import '../modules/admin/views/admin_settings_view.dart';
import '../modules/admin/views/program_view.dart';
import '../modules/admin/views/course_view.dart';
import '../modules/admin/views/instructor_view.dart';
import '../modules/admin/views/student_view.dart';
import '../modules/admin/views/course_assignment_view.dart';
import '../modules/admin/views/attendance_view.dart';
import '../modules/admin/views/analytics_view.dart';
import '../modules/admin/views/main_layout_view.dart';
import '../modules/admin/bindings/admin_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/student/views/student_main_layout.dart';
import '../modules/student/views/pending_passcode_view.dart';
import '../modules/student/views/scan_qr_view.dart';
import '../modules/student/bindings/student_binding.dart';
import '../modules/professor/views/professor_main_layout.dart';
import '../modules/professor/views/take_attendance_view.dart';
import '../modules/professor/views/manage_passcodes_view.dart';
import '../modules/professor/bindings/professor_binding.dart';
import '../modules/professor/views/qr_attendance_view.dart';

abstract class AppRoutes {
  static const String login = '/login';
  static const String studentDashboard = '/student/dashboard';
  static const String professorDashboard = '/professor/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String takeAttendance = '/professor/take-attendance';
  static const String managePasscodes = '/professor/manage-passcodes';
  static const String pendingPasscode = '/student/pending-passcode';
  static const String scanQr = '/student/scan-qr';
  static const String adminSettings = '/admin/settings';

  // Admin sub-routes
  static const String adminPrograms = '/admin/dashboard/programs';
  static const String adminCourses = '/admin/dashboard/courses';
  static const String adminInstructors = '/admin/dashboard/instructors';
  static const String adminStudents = '/admin/dashboard/students';
  static const String adminAssignCourses = '/admin/dashboard/assign-courses';
  static const String adminAttendance = '/admin/dashboard/attendance';
  static const String adminAnalytics = '/admin/dashboard/analytics';

  static final List<GetPage> pages = [
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: studentDashboard,
      page: () => StudentMainLayout(),
      binding: StudentBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: professorDashboard,
      page: () => ProfessorMainLayout(),
      binding: ProfessorBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: adminDashboard,
      page: () => MainLayoutView(),
      binding: AdminBinding(),
      transition: Transition.fadeIn,
      children: [
        GetPage(
          name: '/programs',
          page: () => ProgramView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/courses',
          page: () => CourseView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/instructors',
          page: () => InstructorView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/students',
          page: () => StudentView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/assign-courses',
          page: () => CourseAssignmentView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/attendance',
          page: () => AttendanceView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/analytics',
          page: () => const AnalyticsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
      ],
    ),
    GetPage(
      name: takeAttendance,
      page: () {
        final courseId = Get.parameters['courseId'] ?? '';
        final courseName = Get.parameters['courseName'] ?? '';
        return TakeAttendanceView(
          courseId: courseId,
          courseName: courseName,
        );
      },
      binding: ProfessorBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: managePasscodes,
      page: () {
        final courseId = Get.parameters['courseId'] ?? '';
        final courseName = Get.parameters['courseName'] ?? '';
        final scannedStudentIds = Get.parameters['scannedStudentIds']?.split(',') ?? [];
        return ManagePasscodesView(
          courseId: courseId,
          courseName: courseName,
          scannedStudentIds: scannedStudentIds,
        );
      },
      binding: ProfessorBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: pendingPasscode,
      page: () {
        final courseId = Get.parameters['courseId'] ?? '';
        final courseName = Get.parameters['courseName'] ?? '';
        return PendingPasscodeView(
          courseId: courseId,
          courseName: courseName,
        );
      },
      binding: StudentBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: scanQr,
      page: () => ScanQRView(),
      binding: StudentBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: adminSettings,
      page: () => AdminSettingsView(),
      binding: AdminBinding(),
      transition: Transition.fadeIn,
    ),
  ];
} 