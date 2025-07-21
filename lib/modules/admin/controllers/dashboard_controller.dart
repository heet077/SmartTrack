import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import '../../../routes/app_routes.dart';
import '../../../services/supabase_service.dart';
import '../../../services/course_import_service.dart';

class DashboardController extends GetxController {
  final totalStudents = 0.obs;
  final totalInstructors = 0.obs;
  final totalCourses = 0.obs;
  final totalPrograms = 0.obs;
  final isImporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      // Load total students
      final studentsResponse = await SupabaseService.client
          .from('students')
          .select('id');
      totalStudents.value = (studentsResponse as List).length;

      // Load total instructors
      final instructorsResponse = await SupabaseService.client
          .from('instructors')
          .select('id');
      totalInstructors.value = (instructorsResponse as List).length;

      // Load total courses
      final coursesResponse = await SupabaseService.client
          .from('courses')
          .select('id');
      totalCourses.value = (coursesResponse as List).length;

      // Load total programs
      final programsResponse = await SupabaseService.client
          .from('programs')
          .select('id');
      totalPrograms.value = (programsResponse as List).length;
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Future<void> initializeInstructors() async {
    try {
      final instructors = [
        // BTech Sem-I instructors
        {'name': 'SS', 'email': 'ss@daiict.ac.in', 'username': 'ss@daiict.ac.in', 'short_name': 'SS', 'password': 'password123'},
        {'name': 'RC', 'email': 'rc@daiict.ac.in', 'username': 'rc@daiict.ac.in', 'short_name': 'RC', 'password': 'password123'},
        {'name': 'RLD', 'email': 'rld@daiict.ac.in', 'username': 'rld@daiict.ac.in', 'short_name': 'RLD', 'password': 'password123'},
        {'name': 'PK', 'email': 'pk@daiict.ac.in', 'username': 'pk@daiict.ac.in', 'short_name': 'PK', 'password': 'password123'},
        {'name': 'AM', 'email': 'am@daiict.ac.in', 'username': 'am@daiict.ac.in', 'short_name': 'AM', 'password': 'password123'},
        {'name': 'AM2', 'email': 'am2@daiict.ac.in', 'username': 'am2@daiict.ac.in', 'short_name': 'AM2', 'password': 'password123'},
        {'name': 'SB2', 'email': 'sb2@daiict.ac.in', 'username': 'sb2@daiict.ac.in', 'short_name': 'SB2', 'password': 'password123'},
        {'name': 'AR', 'email': 'ar@daiict.ac.in', 'username': 'ar@daiict.ac.in', 'short_name': 'AR', 'password': 'password123'},
        {'name': 'NJ', 'email': 'nj@daiict.ac.in', 'username': 'nj@daiict.ac.in', 'short_name': 'NJ', 'password': 'password123'},
        {'name': 'VS', 'email': 'vs@daiict.ac.in', 'username': 'vs@daiict.ac.in', 'short_name': 'VS', 'password': 'password123'},
        {'name': 'PK2', 'email': 'pk2@daiict.ac.in', 'username': 'pk2@daiict.ac.in', 'short_name': 'PK2', 'password': 'password123'}
      ];

      await SupabaseService.addInstructorsInBulk(instructors);
      print('Instructors initialized successfully');
    } catch (e) {
      print('Error initializing instructors: $e');
      rethrow;
    }
  }

  Future<void> importCoursesFromCSV() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMedia();

      if (result != null) {
        isImporting.value = true;
        try {
          final file = File(result.path);
          print('Selected file: ${file.path}');
          print('File exists: ${await file.exists()}');
          print('File size: ${await file.length()} bytes');

          // Read first few lines to verify content
          final content = await file.readAsString();
          final lines = content.split('\n');
          print('First few lines of file:');
          for (var i = 0; i < min(5, lines.length); i++) {
            print('Line $i: ${lines[i]}');
          }

          // Import using the service
          await CourseImportService.importDAIICTTimetable(file.path);

          Get.snackbar(
            'Success',
            'Courses imported successfully with assignments and schedules',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            duration: const Duration(seconds: 3),
          );

          // Refresh dashboard data
          await loadDashboardData();
        } catch (e, stackTrace) {
          print('Error during import: $e');
          print('Stack trace: $stackTrace');
          Get.snackbar(
            'Error',
            'Failed to import courses: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
            duration: const Duration(seconds: 5),
          );
        } finally {
          isImporting.value = false;
        }
      }
    } catch (e, stackTrace) {
      print('Error importing courses: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to start import process: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _processTimetableRow(List<dynamic> row) async {
    try {
      final batch = row[1].toString().trim();
      
      // Extract program and semester from batch
      // Example: "BTech Sem-I (ICT + CS)" -> BTECH-ICT-CS, 1
      final programMatch = RegExp(r'BTech.*\((.*?)\)').firstMatch(batch);
      if (programMatch == null) return;
      
      final programName = programMatch.group(1)?.replaceAll(' + ', '-') ?? '';
      final programCode = 'BTECH-${programName.replaceAll(' ', '')}';
      
      final semesterMatch = RegExp(r'Sem-(\w+)').firstMatch(batch);
      final semester = _romanToInt(semesterMatch?.group(1) ?? 'I');

      // Process Monday courses (columns 3-9)
      await _processDayCourses(row, 3, programCode, semester, 'Monday', '8:00 - 8:50');
      
      // Process Tuesday courses (columns 10-16)
      await _processDayCourses(row, 10, programCode, semester, 'Tuesday', '8:00 - 8:50');
      
      // Process Wednesday courses (columns 17-23)
      await _processDayCourses(row, 17, programCode, semester, 'Wednesday', '8:00 - 8:50');
      
      // Process Thursday courses (columns 24-30)
      await _processDayCourses(row, 24, programCode, semester, 'Thursday', '8:00 - 8:50');
      
      // Process Friday courses (columns 31-37)
      await _processDayCourses(row, 31, programCode, semester, 'Friday', '8:00 - 8:50');

    } catch (e) {
      print('Error processing row: $e');
    }
  }

  Future<void> _processDayCourses(List<dynamic> row, int startCol, String programCode, int semester, String day, String timeSlot) async {
    try {
      if (row[startCol] == null || row[startCol].toString().trim().isEmpty) return;

      final courseCode = row[startCol].toString().trim();
      final courseName = row[startCol + 1]?.toString().trim() ?? '';
      if (courseName.isEmpty) return;

      // Parse course details (e.g., "3-0-2-4" format)
      final hoursMatch = RegExp(r'(\d+)-(\d+)-(\d+)-(\d+)').firstMatch(row[startCol + 2]?.toString() ?? '');
      if (hoursMatch == null) return;

      final theoryHours = int.parse(hoursMatch.group(1) ?? '0');
      final tutorialHours = int.parse(hoursMatch.group(2) ?? '0');
      final labHours = int.parse(hoursMatch.group(3) ?? '0');
      final credits = int.parse(hoursMatch.group(4) ?? '0');

      final courseType = row[startCol + 3]?.toString().trim() ?? 'Core';
      final instructorShortName = row[startCol + 4]?.toString().trim() ?? '';
      final classroom = row[startCol + 5]?.toString().trim() ?? '';

      // Create course data
      final courseData = {
        'code': courseCode,
        'name': courseName.replaceAll(RegExp(r'\s*\([^)]*\)'), ''), // Remove section info
        'program_id': programCode,
        'semester': semester,
        'credits': credits,
        'theory_hours': theoryHours,
        'tutorial_hours': tutorialHours,
        'lab_hours': labHours,
        'course_type': _normalizeCourseType(courseType),
      };

      // Get time slot parts
      final times = timeSlot.split(' - ');
      final startTime = times[0];
      final endTime = times[1];

      // Create course and assignment
      await CourseImportService.importCourseWithAssignment(
        courseData,
        instructorShortName, // Pass short name instead of email
        classroom,
        day,
        startTime,
        endTime
      );

    } catch (e) {
      print('Error processing day courses: $e');
    }
  }

  String _normalizeCourseType(String type) {
    final lowercaseType = type.toLowerCase();
    if (lowercaseType.contains('core')) return 'core';
    if (lowercaseType.contains('elective')) {
      if (lowercaseType.contains('technical')) return 'technical_elective';
      if (lowercaseType.contains('open')) return 'open_elective';
    }
    return 'core';
  }

  int _romanToInt(String roman) {
    final values = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8
    };
    return values[roman] ?? 1;
  }

  void navigateToManagePrograms() {
    Get.toNamed(AppRoutes.adminPrograms);
  }

  void navigateToManageCourses() {
    Get.toNamed(AppRoutes.adminCourses);
  }

  void navigateToManageInstructors() {
    Get.toNamed(AppRoutes.adminInstructors);
  }

  void navigateToManageStudents() {
    Get.toNamed(AppRoutes.adminStudents);
  }

  void navigateToAssignCourses() {
    Get.toNamed(AppRoutes.adminAssignCourses);
  }

  void navigateToViewAttendance() {
    Get.toNamed(AppRoutes.adminAttendance);
  }

  void navigateToSettings() {
    Get.toNamed(AppRoutes.adminSettings);
  }
} 