import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class AttendanceController extends GetxController {
  final _supabase = Supabase.instance.client;
  final otpController = TextEditingController();
  
  final isLoading = false.obs;
  final error = ''.obs;
  final attendanceMarked = false.obs;
  final attendanceFinalized = false.obs;
  
  String? currentSessionId;
  String? studentId;

  @override
  void onInit() {
    super.onInit();
    studentId = _supabase.auth.currentUser?.id;
  }

  Future<void> handleScannedCode(String rawCode) async {
    try {
      // Parse QR data
      final qrData = json.decode(utf8.decode(base64Decode(rawCode)));
      
      // Validate QR data format
      if (!qrData.containsKey('session_id') || 
          !qrData.containsKey('timestamp') ||
          !qrData.containsKey('valid_until')) {
        throw Exception('Invalid QR code format');
      }

      final sessionId = qrData['session_id'];
      final validUntil = qrData['valid_until'] as int;

      // Check if QR code has expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > validUntil) {
        throw Exception('QR code has expired');
      }

      // Mark attendance
      await markAttendance(sessionId);
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to process QR code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> markAttendance(String sessionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Check if session exists and is active
      final session = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      if (session == null) {
        throw Exception('Invalid session');
      }

      if (session['finalized'] == true) {
        throw Exception('Session has ended');
      }

      // Record attendance
      await _supabase
          .from('attendance_records')
          .upsert({
            'session_id': sessionId,
            'student_id': studentId,
            'present': true,
            'marked_at': DateTime.now().toIso8601String(),
            'finalized': false,
          });

      currentSessionId = sessionId;
      attendanceMarked.value = true;

      Get.snackbar(
        'Success',
        'Initial attendance marked. Please wait for OTP to finalize.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      error.value = 'Failed to mark attendance: $e';
      Get.snackbar(
        'Error',
        'Failed to mark attendance: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (currentSessionId == null || studentId == null) {
      error.value = 'Invalid session state';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      // Get current session
      final session = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('id', currentSessionId)
          .single();

      if (session == null) {
        throw Exception('Session not found');
      }

      if (!session['otp_enabled']) {
        throw Exception('OTP verification not enabled for this session');
      }

      if (session['end_otp'] != otpController.text) {
        throw Exception('Invalid OTP');
      }

      // Finalize attendance
      await _supabase
          .from('attendance_records')
          .update({
            'finalized': true,
            'finalized_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', currentSessionId)
          .eq('student_id', studentId);

      attendanceFinalized.value = true;

    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to verify OTP: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
} 