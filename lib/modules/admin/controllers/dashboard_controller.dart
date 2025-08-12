import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
      final studentsResponse = await SupabaseService.client
          .from('students')
          .select('id');
      totalStudents.value = (studentsResponse as List).length;

      final instructorsResponse = await SupabaseService.client
          .from('instructors')
          .select('id');
      totalInstructors.value = (instructorsResponse as List).length;

      final coursesResponse = await SupabaseService.client
          .from('courses')
          .select('id');
      totalCourses.value = (coursesResponse as List).length;

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
        {'name': 'PK2', 'email': 'pk2@daiict.ac.in', 'username': 'pk2@daiict.ac.in', 'short_name': 'PK2', 'password': 'password123'},
        {'name': 'Yogesh Verma', 'email': 'yogesh.verma@xai.com', 'username': 'yogesh_v', 'short_name': 'YV', 'password': 'yvpass456'},
        {'name': 'Yash Agrawal', 'email': 'yash.agrawal@xai.com', 'username': 'yash_a', 'short_name': 'YA', 'password': 'yapass321'},
        {'name': 'Vivek S. Patel', 'email': 'vivek.patel@xai.com', 'username': 'vivek_p', 'short_name': 'VSP', 'password': 'vspass456'},
      ];

      await SupabaseService.addInstructorsInBulk(instructors);
      print('Instructors initialized successfully');
    } catch (e) {
      print('Error initializing instructors: $e');
      rethrow;
    }
  }

  Future<void> importCourses() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMedia();
      if (result != null) {
        // Show loading dialog
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Importing Timetable...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we process the file.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );

        isImporting.value = true;
        try {
          final file = File(result.path);
          print('Selected file: ${file.path}');
          print('File exists: ${await file.exists()}');
          print('File size: ${await file.length()} bytes');

          final extension = file.path.split('.').last.toLowerCase();
          if (extension == 'csv') {
            await CourseImportService.importDAIICTTimetable(file.path);
            Get.back(); // Close loading dialog
            Get.snackbar(
              'Success',
              'Timetable imported successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.back(); // Close loading dialog
            throw 'Unsupported file format: $extension. Please use CSV format.';
          }
        } catch (e) {
          Get.back(); // Close loading dialog
          throw e;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to import timetable: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isImporting.value = false;
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