import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class StudentAttendanceMarkingController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Future<bool> markAttendance(String qrData) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Decode the QR data
      final decodedBytes = base64Decode(qrData);
      final decodedString = utf8.decode(decodedBytes);
      final data = json.decode(decodedString);

      // Validate the QR data
      if (!data.containsKey('session_id') || 
          !data.containsKey('timestamp') ||
          !data.containsKey('valid_until')) {
        error.value = 'Invalid QR code format';
        return false;
      }

      final sessionId = data['session_id'];
      final validUntil = data['valid_until'] as int;

      // Check if QR code has expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > validUntil) {
        error.value = 'QR code has expired';
        return false;
      }

      // Get current student ID
      final studentId = _supabase.auth.currentUser?.id;
      if (studentId == null) {
        error.value = 'User not authenticated';
        return false;
      }

      // Check if attendance is already marked
      final existingRecord = await _supabase
          .from('attendance_records')
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingRecord != null) {
        error.value = 'Attendance already marked for this session';
        return false;
      }

      // Mark attendance
      await _supabase
          .from('attendance_records')
          .insert({
            'session_id': sessionId,
            'student_id': studentId,
            'present': true,
            'marked_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      error.value = 'Failed to mark attendance: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 