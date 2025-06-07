import 'package:get/get.dart';
import '../modules/admin/bindings/admin_binding.dart';
import '../modules/admin/views/main_layout_view.dart';
import '../modules/admin/views/admin_login_view.dart';
import '../modules/admin/views/program_view.dart';
import '../modules/admin/views/course_view.dart';
import '../modules/admin/views/instructor_view.dart';
import '../modules/admin/views/student_view.dart';
import '../modules/admin/views/course_assignment_view.dart';
import '../modules/admin/views/attendance_view.dart';
import '../modules/admin/views/settings_view.dart';
import '../modules/admin/views/analytics_view.dart';
import '../modules/admin/views/security_view.dart';
import '../modules/admin/views/support_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/professor/views/professor_main_layout.dart';
import '../modules/student/views/student_main_layout.dart';
import '../modules/student/views/scan_qr_view.dart';
import '../modules/student/bindings/student_binding.dart';
import '../modules/admin/controllers/program_controller.dart';
import '../modules/admin/controllers/course_controller.dart';
import '../modules/admin/controllers/admin_controller.dart';
import '../middleware/auth_middleware.dart';
import '../modules/professor/bindings/professor_binding.dart';

class AppRoutes {
  static final authMiddleware = AuthMiddleware();

  static const String login = '/login';
  static const String professorDashboard = '/professor/dashboard';

  static final routes = [
    GetPage(
      name: login,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/admin/login',
      page: () => const AdminLoginView(),
      binding: BindingsBuilder(() {
        Get.put(AdminController());
      }),
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: '/admin/dashboard',
      page: () => const MainLayoutView(),
      binding: AdminBinding(),
      middlewares: [authMiddleware],
      children: [
        GetPage(
          name: '/programs',
          page: () => const ProgramView(),
        ),
        GetPage(
          name: '/courses',
          page: () => const CourseView(),
        ),
        GetPage(
          name: '/instructors',
          page: () => const InstructorView(),
        ),
        GetPage(
          name: '/students',
          page: () => const StudentView(),
        ),
        GetPage(
          name: '/assign-courses',
          page: () => const CourseAssignmentView(),
        ),
        GetPage(
          name: '/attendance',
          page: () => const AttendanceView(),
        ),
        GetPage(
          name: '/analytics',
          page: () => const AnalyticsView(),
        ),
        GetPage(
          name: '/settings',
          page: () => const SettingsView(),
        ),
        GetPage(
          name: '/security',
          page: () => const SecurityView(),
        ),
        GetPage(
          name: '/support',
          page: () => const SupportView(),
        ),
      ],
    ),
    GetPage(
      name: professorDashboard,
      page: () => const ProfessorMainLayout(),
      binding: ProfessorBinding(),
    ),
    GetPage(
      name: '/student',
      page: () => const StudentMainLayout(),
      binding: StudentBinding(),
      middlewares: [authMiddleware],
      children: [
        GetPage(
          name: '/dashboard',
          page: () => const StudentMainLayout(),
        ),
        GetPage(
          name: '/scan-qr',
          page: () => const ScanQRView(),
        ),
      ],
    ),
  ];
} 