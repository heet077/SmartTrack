import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professor_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_settings/app_settings.dart';

class Student {
  final String id;
  final String name;
  final String enrollmentNo;
  final String programId;
  final String programName;
  RxBool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.enrollmentNo,
    required this.programId,
    required this.programName,
    bool isPresent = false,
  }) : isPresent = isPresent.obs;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      enrollmentNo: json['enrollment_no'],
      programId: json['program']['id'],
      programName: json['program']['name'],
    );
  }
}

class AttendanceController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxString selectedCourse = ''.obs;
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;
  
  final RxList<Map<String, dynamic>> courses = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> attendanceData = <String, dynamic>{}.obs;

  // Calendar-related variables
  final RxMap<DateTime, Map<String, dynamic>> calendarAttendance = <DateTime, Map<String, dynamic>>{}.obs;
  final RxList<DateTime> datesWithAttendance = <DateTime>[].obs;

  final RxList<Student> students = <Student>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with current date
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    loadProfessorCourses();
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure we have a valid date
    if (selectedDate.value == null) {
      final now = DateTime.now();
      selectedDate.value = DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> loadProfessorCourses() async {
    try {
      isLoading.value = true;
      debugPrint('Loading professor courses...');
      
      // Get current user's email
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');
      debugPrint('Current user email: ${currentUser.email}');

      // Get instructor details including program
      final instructor = await _supabase
          .from('instructors')
          .select('*, program:program_id(*)')
          .eq('email', currentUser.email as String)
          .single();

      if (instructor == null) throw Exception('Instructor not found');
      final programId = instructor['program_id'];
      debugPrint('Instructor program ID: $programId');

      // Fetch assigned courses with course details
      final coursesData = await _supabase
          .from('instructor_course_assignments')
          .select('''
            *,
            course:courses!inner (
              id,
              code,
              name,
              program_id
            ),
            schedule:course_schedule_slots (
              id,
              classroom,
              day_of_week,
              start_time,
              end_time
            )
          ''')
          .eq('instructor_id', instructor['id']);

      debugPrint('Fetched courses data: $coursesData');

      // Filter and transform courses data
      courses.value = (coursesData as List).map<Map<String, dynamic>>((assignment) {
        final course = assignment['course'];
        return {
          'id': course['id'],
          'code': course['code'],
          'name': course['name'],
          'program_id': course['program_id'],
          'assignment_id': assignment['id'],
        };
      }).toList();

      debugPrint('Processed courses: ${courses.length}');

      // Load attendance data for each course
      for (var course in courses) {
        await loadAttendanceData(course['id']);
      }

    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAttendanceData(String courseId) async {
    try {
      debugPrint('Loading attendance data for course: $courseId');

      // Get selected date
      final date = selectedDate.value.toIso8601String().split('T')[0];
      debugPrint('Selected date: $date');

      // Get course details
      final course = courses.firstWhere((c) => c['id'] == courseId);
      debugPrint('Loading data for course: ${course['code']}');

      // Get all enrolled students for this course's program
      final enrolledStudents = await _supabase
          .from('students')
          .select('''
            id,
            name,
            enrollment_no,
            program:program_id (
              id,
              name
            )
          ''')
          .eq('program_id', course['program_id']);

      final totalStudents = enrolledStudents.length;
      debugPrint('Found $totalStudents enrolled students for ${course['code']}');

      // For IT615, let's do some extra debugging
      if (course['code'] == 'IT615') {
        debugPrint('=== IT615 Debug Info ===');
        debugPrint('Course ID: $courseId');
        debugPrint('Date: $date');
        
        // First check lecture sessions
        final allSessions = await _supabase
            .from('lecture_sessions')
            .select('*')
            .eq('course_id', courseId);
        debugPrint('All lecture sessions for IT615: $allSessions');
        
        // Then check attendance records
        final allAttendance = await _supabase
            .from('attendance_records')
            .select('*')
            .eq('course_id', courseId);
        debugPrint('All attendance records for IT615: $allAttendance');
        debugPrint('=== End IT615 Debug Info ===');
      }

      // Get lecture session for this date
      final lectureSession = await _supabase
          .from('lecture_sessions')
          .select('*, attendance_records(*)')
          .eq('course_id', courseId)
          .eq('date', date)
          .maybeSingle();

      List<Map<String, dynamic>> attendanceRecords = [];
      String sessionStatus = 'not_started';
      bool isVerified = false;

      if (lectureSession != null) {
        attendanceRecords = List<Map<String, dynamic>>.from(lectureSession['attendance_records'] ?? []);
        isVerified = attendanceRecords.any((record) => record['finalized'] == true);
        sessionStatus = isVerified ? 'completed' : 'in_progress';
        debugPrint('Found lecture session with ${attendanceRecords.length} attendance records');
      } else {
        // If no lecture sessions found, try to get attendance records directly
        final directAttendanceRecords = await _supabase
            .from('attendance_records')
            .select()
            .eq('course_id', courseId)
            .eq('date', date);
            
        if (directAttendanceRecords != null && directAttendanceRecords.isNotEmpty) {
          attendanceRecords = List<Map<String, dynamic>>.from(directAttendanceRecords);
          isVerified = attendanceRecords.any((record) => record['finalized'] == true);
          sessionStatus = isVerified ? 'completed' : 'in_progress';
          debugPrint('Found ${attendanceRecords.length} direct attendance records');
        } else {
          // Check if this is a scheduled day
          final courseSchedule = await _supabase
              .from('course_schedule_slots')
              .select()
              .eq('assignment_id', course['assignment_id'])
              .eq('day_of_week', selectedDate.value.weekday)
              .maybeSingle();

          if (courseSchedule != null) {
            sessionStatus = 'scheduled';
          }
        }
      }

      // Update attendance data for this course
      final presentCount = attendanceRecords.where((record) => 
        record['present'] == true || record['status'] == 'present'
      ).length;
      
      attendanceData[courseId] = {
        'total': totalStudents,
        'present': presentCount,
        'absent': totalStudents - presentCount,
        'records': attendanceRecords,
        'isVerified': isVerified,
        'status': sessionStatus,
        'isScheduledDay': sessionStatus == 'scheduled',
      };

      debugPrint('Attendance data for ${course['code']}: Present: $presentCount, Absent: ${totalStudents - presentCount}, Total: $totalStudents');
      attendanceData.refresh();

    } catch (e) {
      debugPrint('Error loading attendance data: $e');
    }
  }

  Future<void> loadMonthAttendance(String courseId, DateTime month) async {
    try {
      isLoading.value = true;
      
      // Get first and last day of the month
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      
      // Get all lecture sessions for this course in the month
      final sessions = await _supabase
          .from('lecture_sessions')
          .select('*, attendance_records(*)')
          .eq('course_id', courseId)
          .gte('date', firstDay.toIso8601String().split('T')[0])
          .lte('date', lastDay.toIso8601String().split('T')[0]);

      datesWithAttendance.clear();
      
      for (var session in sessions) {
        final date = DateTime.parse(session['date']);
        datesWithAttendance.add(date);
      }
      
      datesWithAttendance.refresh();
      
    } catch (e) {
      debugPrint('Error loading month attendance: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeDate(DateTime date) {
    // Normalize the date to remove time component
    selectedDate.value = DateTime(date.year, date.month, date.day);
    for (var course in courses) {
      loadAttendanceData(course['id']);
    }
  }

  Map<String, dynamic> get currentAttendance {
    final courseId = courses.firstWhere(
      (course) => course['code'] == selectedCourse.value,
      orElse: () => {'id': ''}
    )['id'];
    
    return courseId.isNotEmpty ? attendanceData[courseId] ?? {} : {};
  }
  
  List<Map<String, dynamic>> get currentStudents => 
      List<Map<String, dynamic>>.from(currentAttendance['students'] ?? []);

  void changeCourse(String courseCode) {
    selectedCourse.value = courseCode;
    final courseId = courses.firstWhere(
      (course) => course['code'] == courseCode,
      orElse: () => {'id': ''}
    )['id'];
    
    if (courseId.isNotEmpty) {
      loadAttendanceData(courseId);
    }
  }

  // Cache for enrolled students
  final RxMap<String, List<Map<String, dynamic>>> _enrolledStudentsCache = <String, List<Map<String, dynamic>>>{}.obs;

  Future<void> loadEnrolledStudents(String courseId) async {
    try {
      if (_enrolledStudentsCache.containsKey(courseId)) return;

      final course = courses.firstWhere((c) => c['id'] == courseId);
      final enrolledStudents = await _supabase
          .from('students')
          .select('''
            id,
            name,
            enrollment_no,
            program:program_id (
              id,
              name
            )
          ''')
          .eq('program_id', course['program_id']);

      _enrolledStudentsCache[courseId] = List<Map<String, dynamic>>.from(enrolledStudents);
      debugPrint('Loaded ${_enrolledStudentsCache[courseId]?.length} enrolled students for course $courseId');
    } catch (e) {
      debugPrint('Error loading enrolled students: $e');
      _enrolledStudentsCache[courseId] = [];
    }
  }

  List<Map<String, dynamic>> getEnrolledStudents(String courseId) {
    if (!_enrolledStudentsCache.containsKey(courseId)) {
      loadEnrolledStudents(courseId);
      return [];
    }
    return _enrolledStudentsCache[courseId] ?? [];
  }

  Future<void> preloadCourseData(String courseId) async {
    try {
      // Load attendance data if not already loaded
      if (!attendanceData.containsKey(courseId)) {
        await loadAttendanceData(courseId);
      }

      // Load enrolled students if not already cached
      if (!_enrolledStudentsCache.containsKey(courseId)) {
        await loadEnrolledStudents(courseId);
      }
    } catch (e) {
      debugPrint('Error preloading course data: $e');
    }
  }

  Future<void> loadStudentsForCourse(String courseId) async {
    try {
      isLoading.value = true;
      students.clear();

      // Get course details
      final course = courses.firstWhere((c) => c['id'] == courseId);
      
      // Get all enrolled students
      final enrolledStudents = await _supabase
          .from('students')
          .select('''
            id,
            name,
            enrollment_no,
            program:program_id (
              id,
              name
            )
          ''')
          .eq('program_id', course['program_id']);

      // Get today's attendance records
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceRecords = await _supabase
          .from('attendance_records')
          .select()
          .eq('course_id', courseId)
          .eq('date', today);

      // Create Student objects with attendance status
      students.value = (enrolledStudents as List).map<Student>((data) {
        final isPresent = (attendanceRecords as List).any((record) => 
          record['student_id'] == data['id'] && 
          (record['present'] == true || record['status'] == 'present')
        );
        return Student.fromJson(data)..isPresent.value = isPresent;
      }).toList();

    } catch (e) {
      debugPrint('Error loading students: $e');
      Get.snackbar(
        'Error',
        'Failed to load students',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAttendance(String studentId, String courseId, bool isPresent) async {
    try {
      // Get current date
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get or create lecture session
      final sessionData = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', today)
          .maybeSingle();

      String sessionId;
      if (sessionData == null) {
        // Create new session
        final newSession = await _supabase
            .from('lecture_sessions')
            .insert({
              'course_id': courseId,
              'date': today,
              'start_time': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        sessionId = newSession['id'];
      } else {
        sessionId = sessionData['id'];
      }

      // Update or create attendance record
      await _supabase
          .from('attendance_records')
          .upsert({
            'student_id': studentId,
            'session_id': sessionId,
            'course_id': courseId,
            'date': today,
            'present': isPresent,
            'status': isPresent ? 'present' : 'absent',
            'finalized': true,
            'finalized_at': DateTime.now().toIso8601String(),
          });

      // Update local state
      final student = students.firstWhere((s) => s.id == studentId);
      student.isPresent.value = isPresent;
      students.refresh();

      // Refresh attendance data
      await loadAttendanceData(courseId);
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      Get.snackbar(
        'Error',
        'Failed to mark attendance',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> exportAttendanceToCSV(String courseId) async {
    try {
      // Get course details
      final course = courses.firstWhere((c) => c['id'] == courseId);
      
      // Get all attendance records for this course
      final attendanceRecords = await _supabase
          .from('attendance_records')
          .select('''
            *,
            student:student_id (
              name,
              enrollment_no
            ),
            session:session_id (
              date
            )
          ''')
          .eq('course_id', courseId)
          .order('date');

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Date', 'Student Name', 'Enrollment No', 'Status', 'Verification Time']
      ];

      for (var record in attendanceRecords) {
        csvData.add([
          record['session']['date'],
          record['student']['name'],
          record['student']['enrollment_no'],
          record['status'],
          record['finalized_at'] ?? record['marked_at'] ?? 'N/A',
        ]);
      }

      // Generate CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory for saving file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${course['code']}_attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Write CSV to file
      final file = File(filePath);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareFiles(
        [filePath],
        text: 'Attendance Report for ${course['code']}',
      );
    } catch (e) {
      debugPrint('Error exporting attendance: $e');
      Get.snackbar(
        'Error',
        'Failed to export attendance data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 