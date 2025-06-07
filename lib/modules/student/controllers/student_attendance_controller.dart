import 'package:get/get.dart';

class StudentAttendanceController extends GetxController {
  final RxString selectedSemester = 'Fall 2023'.obs;
  final RxString selectedMonth = 'October'.obs;

  final List<String> semesters = [
    'Fall 2023',
    'Spring 2024',
    'Summer 2024',
  ];

  final List<String> months = [
    'September',
    'October',
    'November',
    'December',
  ];

  final RxList<CourseAttendance> courseAttendances = <CourseAttendance>[
    CourseAttendance(
      subject: 'Data Structures',
      attended: 24,
      total: 30,
      percentage: 0.80,
      isWarning: false,
    ),
    CourseAttendance(
      subject: 'Database Systems',
      attended: 27,
      total: 30,
      percentage: 0.90,
      isWarning: false,
    ),
    CourseAttendance(
      subject: 'Operating Systems',
      attended: 21,
      total: 30,
      percentage: 0.70,
      isWarning: true,
    ),
    CourseAttendance(
      subject: 'Computer Networks',
      attended: 22,
      total: 30,
      percentage: 0.73,
      isWarning: true,
    ),
  ].obs;

  void updateSemester(String semester) {
    selectedSemester.value = semester;
    // TODO: Fetch attendance data for selected semester
  }

  void updateMonth(String month) {
    selectedMonth.value = month;
    // TODO: Fetch attendance data for selected month
  }
}

class CourseAttendance {
  final String subject;
  final int attended;
  final int total;
  final double percentage;
  final bool isWarning;

  CourseAttendance({
    required this.subject,
    required this.attended,
    required this.total,
    required this.percentage,
    required this.isWarning,
  });
} 