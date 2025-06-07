import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AttendanceController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxDouble overallAttendancePercentage = 0.0.obs;
  final RxDouble todayAttendancePercentage = 0.0.obs;
  final RxList attendanceRecords = [].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendanceData();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    loadAttendanceData();
  }

  Future<void> loadAttendanceData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Load overall attendance
      final overallResponse = await SupabaseService.client
          .rpc('calculate_overall_attendance')
          .select();
      
      if (overallResponse != null && overallResponse.isNotEmpty) {
        final percentage = overallResponse[0]['percentage'];
        overallAttendancePercentage.value = 
            (percentage != null ? percentage.toDouble() : 0.0) * 100;
      }

      // Load today's attendance
      final today = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final todayResponse = await SupabaseService.client
          .from('attendance_records')
          .select('*, lecture_sessions(*)')
          .eq('date', today);

      if (todayResponse != null) {
        final records = List<Map<String, dynamic>>.from(todayResponse);
        final presentCount = records.where((r) => r['present'] == true).length;
        todayAttendancePercentage.value = 
            records.isEmpty ? 0.0 : (presentCount.toDouble() / records.length.toDouble()) * 100;
      }

      // Load course-wise attendance
      final courseResponse = await SupabaseService.client
          .from('courses')
          .select('''
            *,
            lecture_sessions(
              *,
              attendance_records(*)
            )
          ''');

      if (courseResponse != null) {
        final courses = List<Map<String, dynamic>>.from(courseResponse);
        attendanceRecords.value = courses.map((course) {
          final sessions = List<Map<String, dynamic>>.from(
              course['lecture_sessions'] ?? []);
          
          int totalAttendance = 0;
          int presentAttendance = 0;

          for (var session in sessions) {
            final records = List<Map<String, dynamic>>.from(
                session['attendance_records'] ?? []);
            totalAttendance += records.length;
            presentAttendance += records
                .where((record) => record['present'] == true)
                .length;
          }

          return {
            'courseCode': course['code'],
            'courseName': course['name'],
            'totalStudents': totalAttendance,
            'presentStudents': presentAttendance,
            'attendancePercentage': totalAttendance == 0
                ? 0.0
                : (presentAttendance.toDouble() / totalAttendance.toDouble()) * 100,
          };
        }).toList();
      }

    } catch (e) {
      error.value = 'Failed to load attendance data: $e';
      print('Error loading attendance data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportAsCSV() async {
    // Implement CSV export logic
    try {
      // TODO: Implement CSV export
      Get.snackbar(
        'Export CSV',
        'CSV export will be implemented soon',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export CSV: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> exportAsPDF() async {
    // Implement PDF export logic
    try {
      // TODO: Implement PDF export
      Get.snackbar(
        'Export PDF',
        'PDF export will be implemented soon',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 