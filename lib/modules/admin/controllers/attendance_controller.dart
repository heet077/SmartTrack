import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:collection/collection.dart';

class AttendanceController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList programs = [].obs;
  final RxList semesters = [].obs;
  final RxList studentAttendance = [].obs;
  final RxString selectedProgram = ''.obs;
  final RxInt selectedSemester = 0.obs;
  final RxDouble overallAttendancePercentage = 0.0.obs;
  final RxString selectedProgramName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDatabase();
    loadPrograms();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Execute the SQL to update the get_detailed_student_attendance function
      await SupabaseService.client.rpc('exec_sql', params: {
        'sql': '''
        -- Drop existing function if it exists
        DROP FUNCTION IF EXISTS get_detailed_student_attendance(UUID, INTEGER);

        -- Create function to get detailed student attendance
        CREATE OR REPLACE FUNCTION get_detailed_student_attendance(
          p_program_id UUID,
          p_semester INTEGER
        )
        RETURNS TABLE (
          student_id UUID,
          student_name TEXT,
          enrollment_no TEXT,
          course_id UUID,
          course_name TEXT,
          attendance_date DATE,
          status BOOLEAN,
          verification_method TEXT
        ) AS \$\$
        BEGIN
          RETURN QUERY
          WITH student_list AS (
            -- Get all students in the program and semester
            SELECT 
              s.id,
              s.name,
              s.enrollment_no
            FROM 
              public.students s
            WHERE 
              s.program_id = p_program_id
              AND s.semester = p_semester::INT4
          ),
          course_dates AS (
            -- Get all course sessions for the program and semester
            SELECT DISTINCT 
              c.id as course_id,
              c.name as course_name,
              ls.date as session_date
            FROM 
              courses c
              JOIN lecture_sessions ls ON ls.course_id = c.id
            WHERE 
              c.program_id = p_program_id
              AND c.semester = p_semester::INT4
              AND ls.finalized = true
          )
          SELECT 
            sl.id as student_id,
            sl.name as student_name,
            sl.enrollment_no,
            cd.course_id,
            cd.course_name,
            cd.session_date as attendance_date,
            COALESCE(ar.present, false) as status,
            CASE 
              WHEN ar.id IS NOT NULL THEN 
                CASE 
                  WHEN ar.status = 'verified' THEN 'Verified'
                  ELSE 'Manual'
                END
              ELSE 'Not Recorded'
            END as verification_method
          FROM 
            student_list sl
            CROSS JOIN course_dates cd
            LEFT JOIN lecture_sessions ls ON ls.date = cd.session_date AND ls.course_id = cd.course_id
            LEFT JOIN attendance_records ar ON ar.session_id = ls.id AND ar.student_id = sl.id
          ORDER BY 
            sl.enrollment_no,
            cd.session_date,
            cd.course_name;
        END;
        \$\$ LANGUAGE plpgsql;

        -- Grant necessary permissions
        GRANT EXECUTE ON FUNCTION get_detailed_student_attendance(UUID, INTEGER) TO authenticated;
        '''
      });
    } catch (e) {
      print('Error initializing database: $e');
      // Don't throw the error - just log it and continue
      // The function might already exist with the correct definition
    }
  }

  Future<void> loadPrograms() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await SupabaseService.client
          .from('programs')
          .select('*')
          .order('name');

      if (response != null) {
        programs.value = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      error.value = 'Failed to load programs: $e';
      print('Error loading programs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSemesters(String programId) async {
    try {
      isLoading.value = true;
      error.value = '';
      selectedProgram.value = programId;
      
      // Get the total number of semesters for this program
      final programResponse = await SupabaseService.client
          .from('programs')
          .select('total_semesters')
          .eq('id', programId)
          .single();

      if (programResponse != null) {
        // Default to 8 semesters if total_semesters is null
        final totalSemesters = programResponse['total_semesters'] ?? 8;
        semesters.value = List.generate(totalSemesters, (index) => index + 1);
      }
    } catch (e) {
      error.value = 'Failed to load semesters: $e';
      print('Error loading semesters: $e');
      // Set default 8 semesters if there's an error
      semesters.value = List.generate(8, (index) => index + 1);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStudentAttendance(String programId, int semester) async {
    try {
      isLoading.value = true;
      error.value = '';
      selectedSemester.value = semester;

      // Get program name
      final programResponse = await SupabaseService.client
          .from('programs')
          .select('name')
          .eq('id', programId)
          .single();
      
      if (programResponse != null) {
        selectedProgramName.value = programResponse['name'];
      }

      print('Fetching attendance for program: $programId, semester: $semester');

      // Get all the data we need
      final detailedAttendance = await _getDetailedAttendance();
      
      // Group records by student and course
      Map<String, Map<String, List<Map<String, dynamic>>>> studentCourseRecords = {};
      
      // First, organize records by student and course
      for (var record in detailedAttendance) {
        final studentId = record['student_id'];
        final courseId = record['course_id'];
        
        studentCourseRecords.putIfAbsent(studentId, () => {});
        studentCourseRecords[studentId]!.putIfAbsent(courseId, () => []);
        studentCourseRecords[studentId]![courseId]!.add(record);
      }

      // Calculate statistics for each student
      Map<String, Map<String, dynamic>> studentStats = {};
      
      for (var studentId in studentCourseRecords.keys) {
        var studentRecords = studentCourseRecords[studentId]!;
        var firstRecord = studentRecords.values.first.first; // Get student info from first record
        
        int totalClasses = 0;
        int classesAttended = 0;
        
        // Count for each course
        for (var courseRecords in studentRecords.values) {
          totalClasses += courseRecords.length;
          classesAttended += courseRecords.where((r) => r['status'] == true).length;
        }
        
        studentStats[studentId] = {
          'student_id': studentId,
          'student_name': firstRecord['student_name'],
          'enrollment_no': firstRecord['enrollment_no'],
          'total_classes': totalClasses,
          'classes_attended': classesAttended,
        };
      }

      // Convert to list and calculate percentages
      studentAttendance.value = studentStats.values.map((stats) {
        double percentage = stats['total_classes'] > 0 
          ? (stats['classes_attended'] / stats['total_classes']) * 100 
          : 0.0;
        
          return {
          'student_id': stats['student_id'],
          'student_name': stats['student_name'],
          'enrollment_no': stats['enrollment_no'],
          'total_classes': stats['total_classes'],
          'classes_attended': stats['classes_attended'],
          'attendance_percentage': percentage,
          };
        }).toList();

      // Calculate overall attendance
      if (studentAttendance.isNotEmpty) {
        double totalPercentage = 0;
        for (var record in studentAttendance) {
          totalPercentage += (record['attendance_percentage'] ?? 0).toDouble();
        }
        overallAttendancePercentage.value = totalPercentage / studentAttendance.length;
        print('Loaded ${studentAttendance.length} student records with overall attendance: ${overallAttendancePercentage.value}%');
      } else {
        overallAttendancePercentage.value = 0;
        print('No attendance records found for program $programId, semester $semester');
      }

      // Print detailed stats for debugging
      for (var record in studentAttendance) {
        print('Student ${record['student_name']}: ${record['classes_attended']} attended out of ${record['total_classes']} total classes (${record['attendance_percentage'].toStringAsFixed(1)}%)');
      }

    } catch (e, stackTrace) {
      error.value = 'Failed to load student attendance: $e';
      print('Error loading student attendance: $e');
      print('Stack trace: $stackTrace');
      studentAttendance.value = [];
      overallAttendancePercentage.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _getSaveDirectory() async {
    try {
      if (Platform.isAndroid) {
        // First check if we have storage permission
        final storagePermission = await Permission.storage.status;
        final manageStoragePermission = await Permission.manageExternalStorage.status;
        
        if (!storagePermission.isGranted || !manageStoragePermission.isGranted) {
          // Request permissions if not granted
          await Permission.storage.request();
          await Permission.manageExternalStorage.request();
          
          // Check again after request
          if (!await Permission.storage.isGranted || !await Permission.manageExternalStorage.isGranted) {
            throw Exception('Storage permission is required');
          }
        }
        
        // Try different storage options in order of preference
        try {
          // First try the Downloads directory
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            return downloadsDir.path;
          }
        } catch (e) {
          print('Error accessing Downloads directory: $e');
        }
        
        try {
          // Then try external storage
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            return externalDir.path;
          }
        } catch (e) {
          print('Error accessing external storage: $e');
        }
        
        // Finally fall back to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        return appDir.path;
      } else {
        // For other platforms, use the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        return directory.path;
      }
    } catch (e) {
      print('Error getting save directory: $e');
      throw Exception('Could not access storage: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getDetailedAttendance() async {
    try {
      print('Getting detailed attendance for program: ${selectedProgram.value}, semester: ${selectedSemester.value}');

      // First verify if we have the required data
      if (selectedProgram.value.isEmpty) {
        print('No program selected');
        throw Exception('No program selected');
      }

      if (selectedSemester.value == 0) {
        print('No semester selected');
        throw Exception('No semester selected');
      }

      // Debug: Check students
      final studentsResponse = await SupabaseService.client
          .from('students')
          .select('id, name, enrollment_no')
          .eq('program_id', selectedProgram.value)
          .eq('semester', selectedSemester.value);
      
      final students = List<Map<String, dynamic>>.from(studentsResponse ?? []);
      print('Found ${students.length} students');
      if (students.isEmpty) {
        print('No students found for this program and semester');
        return [];
      }
      print('Sample student: ${students.first}');

      // Debug: Check courses
      final coursesResponse = await SupabaseService.client
          .from('courses')
          .select('id, name')
          .eq('program_id', selectedProgram.value)
          .eq('semester', selectedSemester.value);
      
      final courses = List<Map<String, dynamic>>.from(coursesResponse ?? []);
      print('Found ${courses.length} courses');
      if (courses.isEmpty) {
        print('No courses found for this program and semester');
        return [];
      }
      print('Sample course: ${courses.first}');

      // Debug: Check lecture sessions
      final courseIds = courses.map((c) => c['id']).toList();
      print('Looking for sessions for course IDs: $courseIds');
      
      // Get all sessions (including non-finalized since we know there's attendance data)
      final sessionsResponse = await SupabaseService.client
          .from('lecture_sessions')
          .select('id, course_id, date, finalized')
          .filter('course_id', 'in', courseIds);
      
      final sessions = List<Map<String, dynamic>>.from(sessionsResponse ?? []);
      print('Found ${sessions.length} lecture sessions');
      if (sessions.isEmpty) {
        print('No lecture sessions found for these courses');
        return [];
      }
      print('Sample session: ${sessions.first}');

      // Print session details for debugging
      for (var session in sessions) {
        print('Session: ${session['id']}, Course: ${session['course_id']}, Date: ${session['date']}, Finalized: ${session['finalized']}');
      }

      // Debug: Check attendance records
      final sessionIds = sessions.map((s) => s['id']).toList();
      final attendanceResponse = await SupabaseService.client
          .from('attendance_records')
          .select('id, student_id, session_id, present, status')
          .filter('session_id', 'in', sessionIds);
      
      final attendance = List<Map<String, dynamic>>.from(attendanceResponse ?? []);
      print('Found ${attendance.length} attendance records');
      if (attendance.isNotEmpty) {
        print('Sample attendance record: ${attendance.first}');
        // Print attendance details for debugging
        for (var record in attendance) {
          print('Attendance: Session ${record['session_id']}, Student: ${record['student_id']}, Present: ${record['present']}, Status: ${record['status']}');
        }
      } else {
        print('No attendance records found');
      }

      // Now build the detailed attendance records manually
      List<Map<String, dynamic>> detailedAttendance = [];

      // Calculate attendance statistics for each student
      Map<String, Map<String, dynamic>> studentStats = {};
      
      // Initialize stats for each student
      for (var student in students) {
        studentStats[student['id']] = {
          'student_id': student['id'],
          'student_name': student['name'],
          'enrollment_no': student['enrollment_no'],
          'total_classes': sessions.length, // Total number of sessions
          'classes_attended': 0,
          'attendance_records': <Map<String, dynamic>>[]
        };
      }

      // Calculate attendance for each student
      for (var session in sessions) {
        for (var student in students) {
          var attendanceRecord = attendance.firstWhereOrNull(
            (a) => a['session_id'] == session['id'] && a['student_id'] == student['id'],
          );

          var record = {
            'student_id': student['id'],
            'student_name': student['name'],
            'enrollment_no': student['enrollment_no'],
            'course_id': session['course_id'],
            'course_name': courses.firstWhere((c) => c['id'] == session['course_id'])['name'],
            'attendance_date': session['date'],
            'status': attendanceRecord != null ? attendanceRecord['present'] : false,
            'verification_method': attendanceRecord != null 
              ? (attendanceRecord['status'] == 'verified' ? 'Verified' : 'Manual')
              : 'Not Recorded'
          };

          studentStats[student['id']]!['attendance_records'].add(record);
          
          if (attendanceRecord != null && attendanceRecord['present'] == true) {
            studentStats[student['id']]!['classes_attended']++;
          }
        }
      }

      // Calculate percentages and build final records
      for (var stats in studentStats.values) {
        double attendancePercentage = stats['total_classes'] > 0 
          ? (stats['classes_attended'] / stats['total_classes']) * 100 
          : 0.0;

        // Add all detailed records
        detailedAttendance.addAll(stats['attendance_records']);

        // Print stats for debugging
        print('Student ${stats['student_name']}: ${stats['classes_attended']} attended out of ${stats['total_classes']} total classes (${attendancePercentage.toStringAsFixed(1)}%)');
      }

      print('Generated ${detailedAttendance.length} detailed attendance records');
      if (detailedAttendance.isNotEmpty) {
        print('Sample detailed record: ${detailedAttendance.first}');
      } else {
        print('No detailed records generated');
      }
      
      return detailedAttendance;
    } catch (e, stackTrace) {
      print('Error fetching detailed attendance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> exportAsCSV() async {
    try {
      if (studentAttendance.isEmpty) {
        Get.snackbar(
          'Error',
          'No attendance data to export. Please select a program and semester first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
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
                    style: TextStyle(
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

      // Get detailed attendance data
      final detailedAttendance = await _getDetailedAttendance();
      if (detailedAttendance.isEmpty) {
        // Close loading dialog
        Get.back();
        Get.snackbar(
          'No Data',
          'No detailed attendance records found for the selected program and semester.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Group records by student and course
      Map<String, Map<String, List<Map<String, dynamic>>>> studentCourseRecords = {};
      
      // First, organize records by student and course
      for (var record in detailedAttendance) {
        final studentId = record['student_id'];
        final courseId = record['course_id'];
        
        studentCourseRecords.putIfAbsent(studentId, () => {});
        studentCourseRecords[studentId]!.putIfAbsent(courseId, () => []);
        studentCourseRecords[studentId]![courseId]!.add(record);
      }

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Program Info
        ['Program:', selectedProgramName.value],
        ['Semester:', selectedSemester.value.toString()],
        ['Report Generated:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
        [],
        // Headers
        ['Student Name', 'Enrollment No', 'Course', 'Date', 'Status'],
      ];

      // Add detailed attendance data
      for (var studentId in studentCourseRecords.keys) {
        var studentRecords = studentCourseRecords[studentId]!;
        for (var courseId in studentRecords.keys) {
          var courseRecords = studentRecords[courseId]!;
          for (var record in courseRecords) {
            csvData.add([
              record['student_name'],
              record['enrollment_no'],
              record['course_name'],
              DateFormat('yyyy-MM-dd').format(DateTime.parse(record['attendance_date'])),
              record['status'] ? 'Present' : 'Absent',
            ]);
          }
        }
      }

      // Add summary section
      csvData.addAll([
        [],
        ['Attendance Summary'],
        ['Student Name', 'Enrollment No', 'Overall Attendance %', 'Total Classes', 'Classes Attended'],
      ]);

      // Add summary data from studentAttendance
      for (var student in studentAttendance) {
        csvData.add([
          student['student_name'],
          student['enrollment_no'],
          '${(student['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
          student['total_classes'],
          student['classes_attended'],
        ]);
      }

      // Add overall attendance
      csvData.addAll([
        [],
        ['Overall Class Attendance:', '${overallAttendancePercentage.value.toStringAsFixed(1)}%'],
      ]);

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'attendance_${selectedProgramName.value}_sem${selectedSemester.value}_$dateStr.csv'
          .replaceAll(RegExp(r'[^\w\s\-\.]'), '_'); // Sanitize filename
      final file = File('${tempDir.path}/$fileName');

      // Write to temporary file
      await file.writeAsString(csv);

      // Close loading dialog
      Get.back();

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report',
      );

    } catch (e, stackTrace) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error exporting CSV: $e');
      print('Stack trace: $stackTrace');

      String errorMessage = 'Failed to export report';
      if (e.toString().contains('No program selected')) {
        errorMessage = 'Please select a program first';
      } else if (e.toString().contains('No semester selected')) {
        errorMessage = 'Please select a semester first';
      } else if (e.toString().contains('No detailed attendance data')) {
        errorMessage = 'No attendance records found for the selected program and semester';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> exportAsPDF() async {
    try {
      if (studentAttendance.isEmpty) {
        Get.snackbar(
          'Error',
          'No attendance data to export. Please select a program and semester first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
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
                    style: TextStyle(
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

      // Get detailed attendance data
      final detailedAttendance = await _getDetailedAttendance();
      if (detailedAttendance.isEmpty) {
        // Close loading dialog
        Get.back();
        Get.snackbar(
          'No Data',
          'No detailed attendance records found for the selected program and semester.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Program: ${selectedProgramName.value}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Semester: ${selectedSemester.value}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Report Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Overall Attendance: ${overallAttendancePercentage.value.toStringAsFixed(1)}%',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      // Add summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance Summary',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E0E0E0'),
                  ),
                  cellHeight: 30,
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  headers: ['Student Name', 'Enrollment No', 'Overall %', 'Total Classes', 'Classes Attended'],
                  data: studentAttendance.map((student) => [
                    student['student_name'],
                    student['enrollment_no'],
                    '${(student['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
                    student['total_classes']?.toString() ?? '0',
                    student['classes_attended']?.toString() ?? '0',
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Add detailed attendance pages
      final studentGroups = groupBy(detailedAttendance, (record) => record['enrollment_no']);
      
      for (var studentGroup in studentGroups.entries) {
        final studentRecords = studentGroup.value;
        if (studentRecords.isEmpty) continue;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Detailed Attendance - ${studentRecords.first['student_name']}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Enrollment No: ${studentRecords.first['enrollment_no']}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#E0E0E0'),
                    ),
                    cellHeight: 25,
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    headers: ['Date', 'Course', 'Status', 'Verification'],
                    data: studentRecords.map((record) => [
                      DateFormat('yyyy-MM-dd').format(DateTime.parse(record['attendance_date'])),
                      record['course_name'],
                      record['status'] ? 'Present' : 'Absent',
                      record['verification_method'] ?? 'N/A',
                    ]).toList(),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'attendance_${selectedProgramName.value}_sem${selectedSemester.value}_$dateStr.pdf'
          .replaceAll(RegExp(r'[^\w\s\-\.]'), '_'); // Sanitize filename
      final file = File('${tempDir.path}/$fileName');

      // Save PDF to temporary file
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Get.back();

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report',
      );

    } catch (e, stackTrace) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error exporting PDF: $e');
      print('Stack trace: $stackTrace');

      String errorMessage = 'Failed to export report';
      if (e.toString().contains('No program selected')) {
        errorMessage = 'Please select a program first';
      } else if (e.toString().contains('No semester selected')) {
        errorMessage = 'Please select a semester first';
      } else if (e.toString().contains('No detailed attendance data')) {
        errorMessage = 'No attendance records found for the selected program and semester';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchProgramAttendance(String programId, int semester) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_program_attendance_v2', params: {
            'p_program_id': programId,
            'p_semester': semester
          }).select();
      
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error fetching program attendance: $e');
      return [];
    }
  }

  Future<void> exportAllProgramsAsCSV() async {
    try {
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
                    'Generating Complete Attendance Report...',
                    style: TextStyle(
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

      isLoading.value = true;
      
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Program', 'Semester', 'Student Name', 'Enrollment No', 'Attendance Percentage'],
      ];

      // Track unique program-semester combinations to avoid duplicates
      Set<String> addedProgramSemesters = {};

      // Iterate through all programs
      for (var program in programs) {
        String programId = program['id'];
        String programName = program['name'];
        int totalSemesters = program['total_semesters'] ?? 0;

        // For each semester in the program
        for (int semester = 1; semester <= totalSemesters; semester++) {
          final attendanceData = await fetchProgramAttendance(programId, semester);
          
          if (attendanceData.isNotEmpty) {
            // Add student data
            for (var student in attendanceData) {
              String key = '$programName-$semester';
              if (!addedProgramSemesters.contains(key)) {
                // Add a blank line before new program-semester if not the first entry
                if (csvData.length > 1) {
                  csvData.add([]);
                }
                addedProgramSemesters.add(key);
              }

              csvData.add([
                programName,
                semester,
                student['student_name'],
                student['enrollment_no'],
                '${(student['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
              ]);
            }
          }
        }
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'attendance_report_$dateStr.csv'
          .replaceAll(RegExp(r'[^\w\s\-\.]'), '_'); // Sanitize filename
      final file = File('${tempDir.path}/$fileName');

      // Write to file
      await file.writeAsString(csv);

      // Close loading dialog
      Get.back();

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report',
      );

    } catch (e, stackTrace) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error exporting CSV: $e');
      print('Stack trace: $stackTrace');

      Get.snackbar(
        'Error',
        'Failed to generate attendance report',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportAllProgramsAsPDF() async {
    try {
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
                    style: TextStyle(
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

      isLoading.value = true;

      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 40),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E0E0E0'),
                  ),
                  cellHeight: 25,
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  headers: ['Program', 'Semester', 'Student Name', 'Enrollment No', 'Attendance %'],
                  data: [],
                ),
              ],
            );
          },
        ),
      );

      // For each program
      for (var program in programs) {
        String programId = program['id'];
        String programName = program['name'];
        int totalSemesters = program['total_semesters'] ?? 0;

        // For each semester
        for (int semester = 1; semester <= totalSemesters; semester++) {
          final attendanceData = await fetchProgramAttendance(programId, semester);
          
          if (attendanceData.isNotEmpty) {
            // Add data page
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.TableHelper.fromTextArray(
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        headerDecoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#E0E0E0'),
                        ),
                        cellHeight: 25,
                        cellAlignment: pw.Alignment.center,
                        headerAlignment: pw.Alignment.center,
                        headers: ['Program', 'Semester', 'Student Name', 'Enrollment No', 'Attendance %'],
                        data: attendanceData.map((student) => [
                          programName,
                          semester.toString(),
                          student['student_name'],
                          student['enrollment_no'],
                          '${(student['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
                        ]).toList(),
                      ),
                    ],
                  );
                },
              ),
            );
          }
        }
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'attendance_report_$dateStr.pdf'
          .replaceAll(RegExp(r'[^\w\s\-\.]'), '_'); // Sanitize filename
      final file = File('${tempDir.path}/$fileName');

      // Save PDF to temporary file
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Get.back();

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report',
      );

    } catch (e, stackTrace) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error exporting PDF: $e');
      print('Stack trace: $stackTrace');

      Get.snackbar(
        'Error',
        'Failed to generate attendance report',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }
} 