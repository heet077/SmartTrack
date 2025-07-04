import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../views/student_passcode_view.dart';

class QRScannerController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isProcessing = false.obs;
  final RxString error = ''.obs;

  Future<void> handleScannedCode(String code) async {
    try {
      if (isProcessing.value) return;
      
      isProcessing.value = true;
      error.value = '';

      // Decode QR data
      final decodedData = utf8.decode(base64.decode(code));
      final qrData = json.decode(decodedData);

      // Validate QR data
      final sessionId = qrData['session_id'];
      final validUntil = DateTime.fromMillisecondsSinceEpoch(qrData['valid_until']);
      
      if (DateTime.now().isAfter(validUntil)) {
        throw Exception('QR code has expired');
      }

      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Get student ID
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('email', user.email as Object)
          .single();

      if (studentData == null) throw Exception('Student not found');

      // Get session details
      final sessionData = await _supabase
          .from('lecture_sessions')
          .select('*, courses(id, name)')
          .eq('id', sessionId)
          .single();

      // Create attendance record
      await _supabase.from('attendance_records').insert({
        'session_id': sessionId,
        'student_id': studentData['id'],
        'scanned_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'present': false,
        'finalized': false,
      });

      // Navigate to passcode view
      Get.off(() => StudentPasscodeView(
        courseId: sessionData['courses']['id'],
        courseName: sessionData['courses']['name'],
      ));

      Get.snackbar(
        'Success',
        'QR code scanned successfully. Please enter the passcode to complete attendance.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error handling QR code: $e');
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to process QR code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }
} 