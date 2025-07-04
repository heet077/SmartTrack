import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import 'package:flutter/material.dart';

class AnalyticsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> programAttendance = <Map<String, dynamic>>[].obs;
  final RxDouble overallAttendance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProgramAttendance();
  }

  Future<void> loadProgramAttendance() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get all programs
      final programs = await SupabaseService.client
          .from('programs')
          .select('id, name')
          .order('name');

      if (programs == null || programs.isEmpty) {
        error.value = 'No programs found';
        return;
      }

      List<Map<String, dynamic>> attendanceData = [];
      double totalAttendance = 0;
      int programCount = 0;

      // For each program, calculate attendance
      for (var program in programs) {
        String programId = program['id'];
        String programName = program['name'];

        try {
          // Get all lecture sessions for this program's courses
          final sessionsResponse = await SupabaseService.client
              .from('lecture_sessions')
              .select('''
                id,
                course:courses!inner(
                  id,
                  program_id
                )
              ''')
              .eq('courses.program_id', programId);

          if (sessionsResponse != null) {
            final sessions = List<Map<String, dynamic>>.from(sessionsResponse);
            final sessionIds = sessions.map((s) => s['id']).toList();

            if (sessionIds.isNotEmpty) {
              // Get attendance records for these sessions
              final attendanceResponse = await SupabaseService.client
                  .from('attendance_records')
                  .select('id, present, lecture_session_id')
                  .inFilter('lecture_session_id', sessionIds);

              if (attendanceResponse != null) {
                final records = List<Map<String, dynamic>>.from(attendanceResponse);
                final totalRecords = records.length;
                final presentCount = records.where((r) => r['present'] == true).length;

                double attendancePercentage = 0.0;
                if (totalRecords > 0) {
                  attendancePercentage = (presentCount / totalRecords) * 100;
                }

                print('Program: $programName');
                print('Total Records: $totalRecords');
                print('Present Count: $presentCount');
                print('Attendance Percentage: $attendancePercentage%');

                attendanceData.add({
                  'program_name': programName,
                  'attendance_percentage': attendancePercentage,
                  'total_records': totalRecords,
                  'present_count': presentCount,
                  'color': _generateProgramColor(programCount),
                });

                if (totalRecords > 0) {
                  totalAttendance += attendancePercentage;
                  programCount++;
                }
              }
            } else {
              // No sessions found for this program
              attendanceData.add({
                'program_name': programName,
                'attendance_percentage': 0.0,
                'total_records': 0,
                'present_count': 0,
                'color': _generateProgramColor(programCount),
              });
              programCount++;
            }
          }
        } catch (e) {
          print('Error calculating attendance for program $programName: $e');
          attendanceData.add({
            'program_name': programName,
            'attendance_percentage': 0.0,
            'total_records': 0,
            'present_count': 0,
            'color': _generateProgramColor(programCount),
          });
          programCount++;
        }
      }

      programAttendance.value = attendanceData;
      overallAttendance.value = programCount > 0 ? totalAttendance / programCount : 0;

    } catch (e) {
      print('Error loading program attendance: $e');
      error.value = 'Failed to load program attendance';
    } finally {
      isLoading.value = false;
    }
  }

  Color _generateProgramColor(int index) {
    // Define a list of colors for the chart
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
} 