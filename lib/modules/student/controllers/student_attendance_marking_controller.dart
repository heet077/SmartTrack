import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import './location_verification_controller.dart';

class StudentAttendanceMarkingController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool qrScanned = false.obs;
  final RxBool attendanceVerified = false.obs;
  final RxString currentSessionId = ''.obs;
  final RxString currentCourseId = ''.obs;
  final RxString currentDate = ''.obs;
  late final LocationVerificationController _locationController;

  @override
  void onInit() {
    super.onInit();
    _locationController = Get.put(LocationVerificationController());
  }

  Future<bool> markAttendance(String qrData) async {
    try {
      isLoading.value = true;
      error.value = '';

      // First verify location
      final isLocationValid = await _locationController.verifyLocation();
      debugPrint('=== Attendance Marking ===');
      debugPrint('Location verification result: $isLocationValid');
      debugPrint('Location error: ${_locationController.error.value}');
      debugPrint('Is within geofence: ${_locationController.isWithinGeofence.value}');
      debugPrint('=======================');

      if (!isLocationValid) {
        error.value = _locationController.error.value;
        Get.snackbar(
          'Location Error',
          _locationController.error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        isLoading.value = false;
        Get.back(); // Go back to previous screen
        return false;
      }

      // Decode the QR data
      final decodedBytes = base64Decode(qrData);
      final decodedString = utf8.decode(decodedBytes);
      final data = json.decode(decodedString);

      debugPrint('Decoded QR data: $data');

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

      // Get current user's email and fetch corresponding student ID and program ID
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) {
        error.value = 'User not authenticated';
        return false;
      }

      // Get student ID and program details
      final studentData = await _supabase
          .from('students')
          .select('''
            id,
            program:programs (
              id,
              name
            )
          ''')
          .eq('email', userEmail)
          .single();
      
      if (studentData == null) {
        error.value = 'Student record not found';
        return false;
      }

      final studentId = studentData['id'];
      final studentProgramId = studentData['program']['id'];
      final studentProgramName = studentData['program']['name'];

      // Get lecture session details with course and program info
      final sessionData = await _supabase
          .from('lecture_sessions')
          .select('''
            id,
            date,
            course:courses (
              id,
              code,
              name,
              program_id
            )
          ''')
          .eq('id', sessionId)
          .single();

      if (sessionData == null) {
        error.value = 'Invalid lecture session';
        return false;
      }

      // Verify if the course belongs to student's program
      final courseProgramId = sessionData['course']['program_id'];
      if (courseProgramId != studentProgramId) {
        error.value = 'You are not authorized to mark attendance for this course. This course belongs to a different program.';
        Get.snackbar(
          'Unauthorized',
          'You cannot mark attendance for courses outside your program (${studentProgramName})',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      // Check if QR scan already exists
      final existingScan = await _supabase
          .from('student_qr_scans')
          .select()
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .maybeSingle();

      if (existingScan != null) {
        error.value = 'QR code already scanned for this session';
        return false;
      }

      // Record QR scan first
      await _supabase
          .from('student_qr_scans')
          .insert({
            'student_id': studentId,
            'session_id': sessionId,
            'scanned_at': DateTime.now().toIso8601String(),
            'status': 'tentative'
          });

      // Create a pending attendance record
      final attendanceResult = await _supabase
          .from('attendance_records')
          .insert({
            'student_id': studentId,
            'course_id': sessionData['course']['id'],
            'session_id': sessionId,
            'date': sessionData['date'],
            'status': 'pending',
            'present': false,
            'marked_at': DateTime.now().toIso8601String()
          })
          .select()
          .single();

      currentSessionId.value = sessionId;
      currentCourseId.value = sessionData['course']['id'];
      currentDate.value = sessionData['date'];
      qrScanned.value = true;

      // Show success message and return to dashboard
      Get.snackbar(
        'QR Code Scanned',
        'QR code scanned successfully. Please wait for the professor to provide the passcode.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Wait for snackbar to be visible before navigation
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate back to dashboard
      Get.offAllNamed('/student/dashboard');
      
      return true;
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to process QR code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyPasscode(String passcode) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get current user's email
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) {
        error.value = 'User not authenticated';
        return false;
      }

      // Get student ID
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('email', userEmail)
          .single();
      
      if (studentData == null) {
        error.value = 'Student record not found';
        return false;
      }

      final studentId = studentData['id'];

      // Verify passcode against active session
      final sessionData = await _supabase
          .from('lecture_sessions')
          .select('id, passcode')
          .eq('id', currentSessionId.value)
          .single();

      if (sessionData == null) {
        error.value = 'Session not found';
        return false;
      }

      if (sessionData['passcode'] != passcode) {
        error.value = 'Invalid passcode';
        Get.snackbar(
          'Error',
          'Invalid passcode. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Update attendance record to mark as present
      await _supabase
          .from('attendance_records')
          .update({
            'present': true,
            'status': 'verified',
            'verification_type': 'passcode',
            'verified_at': DateTime.now().toIso8601String()
          })
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId.value);

      // Update QR scan status to finalized
      await _supabase
          .from('student_qr_scans')
          .update({'status': 'finalized'})
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId.value);

      attendanceVerified.value = true;
      Get.snackbar(
        'Success',
        'Attendance marked successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      error.value = 'Error verifying passcode: $e';
      Get.snackbar(
        'Error',
        'Failed to verify passcode: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    qrScanned.value = false;
    attendanceVerified.value = false;
    currentSessionId.value = '';
    currentCourseId.value = '';
    currentDate.value = '';
    error.value = '';
  }
} 