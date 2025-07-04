import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
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
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.enrollmentNo,
    this.isPresent = false,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      enrollmentNo: json['enrollment_no'] as String,
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
          .from('course_assignments')
          .select('''
            *,
            course:courses!inner (
              id,
              code,
              name,
              program_id
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
          'program_id': course['program_id']
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

      // Get lecture session with more detailed query
      final lectureSessions = await _supabase
          .from('lecture_sessions')
          .select('''
            *,
            attendance_records!left(
              id,
              student_id,
              status,
              present,
              date,
              finalized
            )
          ''')
          .eq('course_id', courseId)
          .eq('date', date);

      debugPrint('Found ${lectureSessions.length} lecture sessions for date');

      List<Map<String, dynamic>> attendanceRecords = [];
      bool isVerified = false;
      String sessionStatus = 'no_class';

      // Process all lecture sessions for the day
      if (lectureSessions != null && lectureSessions.isNotEmpty) {
        // Combine attendance records from all sessions
        for (var session in lectureSessions) {
          final sessionRecords = List<Map<String, dynamic>>.from(session['attendance_records'] ?? []);
          attendanceRecords.addAll(sessionRecords);
          
          // If any session is finalized, mark as verified
          if (session['finalized'] == true) {
            isVerified = true;
          }
        }
        
        sessionStatus = isVerified ? 'completed' : 'in_progress';
        debugPrint('Found ${attendanceRecords.length} attendance records from all sessions');
      
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
              .from('course_assignments')
              .select()
              .eq('course_id', courseId)
              .eq('day_of_week', selectedDate.value.weekday)
              .maybeSingle();
              
          if (courseSchedule != null) {
            sessionStatus = 'scheduled';
            debugPrint('This is a scheduled lecture day for ${course['code']}');
          }
        }
      }

      // Calculate attendance statistics
      final presentStudents = attendanceRecords.where((record) => 
        record['present'] == true || record['status'] == 'present'
      ).length;
      final absentStudents = totalStudents - presentStudents;

      debugPrint('Attendance stats for ${course['code']} - Total: $totalStudents, Present: $presentStudents, Absent: $absentStudents');

      // Store the attendance data
      final attendanceInfo = {
        'total': totalStudents,
        'present': presentStudents,
        'absent': absentStudents,
        'date': DateFormat('MMM dd, yyyy').format(selectedDate.value),
        'isVerified': isVerified,
        'isScheduledDay': sessionStatus != 'no_class',
        'status': sessionStatus,
        'records': attendanceRecords
      };

      attendanceData[courseId] = attendanceInfo;
      calendarAttendance[selectedDate.value] = attendanceInfo;

      debugPrint('Stored attendance data for course $courseId: ${attendanceData[courseId]}');
      attendanceData.refresh();
      calendarAttendance.refresh();

    } catch (e, stackTrace) {
      debugPrint('Error loading attendance data: $e');
      debugPrint('Stack trace: $stackTrace');
      final defaultData = {
        'total': 0,
        'present': 0,
        'absent': 0,
        'date': DateFormat('MMM dd, yyyy').format(selectedDate.value),
        'isVerified': false,
        'isScheduledDay': false,
        'status': 'no_class',
        'records': []
      };
      attendanceData[courseId] = defaultData;
      calendarAttendance[selectedDate.value] = defaultData;
      attendanceData.refresh();
      calendarAttendance.refresh();
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

      // Preload enrolled students
      await loadEnrolledStudents(courseId);
    } catch (e) {
      debugPrint('Error preloading course data: $e');
    }
  }

  Future<void> loadStudentsForCourse(String courseId) async {
    try {
      isLoading.value = true;
      students.clear();

      final response = await _supabase
          .from('students')
          .select('''
            id,
            name,
            enrollment_no
          ''')
          .eq('program_id', (
            await _supabase
                .from('courses')
                .select('program_id')
                .eq('id', courseId)
                .single()
          )['program_id']);

      students.assignAll(
        (response as List).map((data) => Student.fromJson(data)).toList()
      );
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

  Future<void> markAttendance(
    String studentId,
    String courseId,
    bool isPresent,
  ) async {
    try {
      // Get current lecture session
      final sessionResponse = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', DateTime.now().toIso8601String().split('T')[0])
          .single();

      if (sessionResponse == null) {
        throw Exception('No active lecture session found');
      }

      // Update or create attendance record
      await _supabase
          .from('attendance_records')
          .upsert({
            'student_id': studentId,
            'session_id': sessionResponse['id'],
            'course_id': courseId,
            'present': isPresent,
            'status': isPresent ? 'pending' : 'absent',
            'marked_at': DateTime.now().toIso8601String(),
          });

      // Update local state
      final student = students.firstWhere((s) => s.id == studentId);
      student.isPresent = isPresent;
      students.refresh(); // Notify listeners of the change
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

  Future<void> exportAttendanceToCSV(String courseId, DateTime date) async {
    try {
      // Request storage permissions based on Android version
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.request().isGranted &&
            await Permission.storage.request().isGranted) {
          // Permissions granted
        } else {
          Get.snackbar(
            'Permission Denied',
            'Storage permission is required to save attendance data. Please grant permission in app settings.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('OPEN SETTINGS', style: TextStyle(color: Colors.white)),
            ),
          );
          return;
        }
      }

      // Show loading dialog
      Get.dialog(
        Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating Attendance Report...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

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

      // Get attendance records for the date
      final attendanceRecords = await _supabase
          .from('attendance_records')
          .select()
          .eq('course_id', courseId)
          .eq('date', date.toIso8601String().split('T')[0]);

      // Prepare CSV data
      List<List<dynamic>> csvData = [];
      
      // Add header row
      csvData.add([
        'Date',
        'Course Code',
        'Course Name',
        'Enrollment No',
        'Student Name',
        'Status'
      ]);

      // Add data rows
      for (var student in enrolledStudents) {
        final attendance = attendanceRecords.firstWhere(
          (record) => record['student_id'] == student['id'],
          orElse: () => {'present': false, 'status': 'absent'},
        );

        csvData.add([
          DateFormat('yyyy-MM-dd').format(date),
          course['code'],
          course['name'],
          student['enrollment_no'],
          student['name'],
          attendance['present'] == true ? 'Present' : 'Absent'
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName = '${course['code']}_attendance_${DateFormat('yyyy-MM-dd').format(date)}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Write to file
      await file.writeAsString(csv);

      // Close loading dialog
      Get.back();
      
      // Show success message with file path
      Get.snackbar(
        'Success',
        'File saved to Downloads folder: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () => Share.shareXFiles([XFile(filePath)]),
          child: const Text('SHARE', style: TextStyle(color: Colors.white)),
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      debugPrint('Error exporting attendance: $e');
      Get.snackbar(
        'Error',
        'Failed to export attendance data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 