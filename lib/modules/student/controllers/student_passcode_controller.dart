import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_passcode.dart';
import 'dart:async';

class StudentPasscodeController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxBool isValid = false.obs;
  final RxString currentPasscode = ''.obs;
  final RxString expiresIn = ''.obs;
  final RxString error = ''.obs;
  Timer? _expiryTimer;

  @override
  void onClose() {
    _expiryTimer?.cancel();
    super.onClose();
  }

  Future<void> checkPasscode(String courseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get current user's email
      final user = _supabase.auth.currentUser;
      if (user == null) {
        error.value = 'Not authenticated';
        return;
      }

      // Get student ID from email
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('email', user.email as Object)
          .single();

      if (studentData == null) {
        error.value = 'Student not found';
        return;
      }

      debugPrint('Checking passcode for student ${studentData['id']} in course $courseId');

      // Get latest active passcode for the student
      final response = await _supabase
          .from('student_passcodes')
          .select()
          .eq('student_id', studentData['id'])
          .eq('course_id', courseId)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('Passcode response: $response');

      if (response != null) {
        final passcode = StudentPasscode.fromMap(response);
        currentPasscode.value = passcode.passcode;
        isValid.value = true;

        // Start countdown timer
        _startExpiryTimer(passcode.expiresAt);
      } else {
        isValid.value = false;
        currentPasscode.value = '';
        expiresIn.value = '';
      }
    } catch (e) {
      debugPrint('Error checking passcode: $e');
      error.value = 'Failed to check passcode';
      isValid.value = false;
      currentPasscode.value = '';
      expiresIn.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  void _startExpiryTimer(DateTime expiryTime) {
    _expiryTimer?.cancel();
    
    void updateExpiryText() {
      final now = DateTime.now();
      if (now.isAfter(expiryTime)) {
        expiresIn.value = 'Expired';
        _expiryTimer?.cancel();
        isValid.value = false;
        return;
      }

      final difference = expiryTime.difference(now);
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      expiresIn.value = '${minutes}m ${seconds}s';
    }

    // Update immediately
    updateExpiryText();

    // Update every second
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateExpiryText();
    });
  }

  Future<bool> verifyPasscode({
    required String courseId,
    required String passcode,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get current user's email
      final user = _supabase.auth.currentUser;
      if (user == null) {
        error.value = 'Not authenticated';
        return false;
      }

      // Get student ID from email
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('email', user.email as Object)
          .single();

      if (studentData == null) {
        error.value = 'Student not found';
        return false;
      }

      // Check if passcode exists and is valid
      final passcodeData = await _supabase
          .from('student_passcodes')
          .select()
          .eq('student_id', studentData['id'])
          .eq('course_id', courseId)
          .eq('passcode', passcode)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (passcodeData == null) {
        error.value = 'Invalid or expired passcode';
        return false;
      }

      // Mark passcode as used
      await _supabase
          .from('student_passcodes')
          .update({'is_used': true})
          .eq('id', passcodeData['id']);

      // Get current session
      final sessionData = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('date', DateTime.now().toIso8601String().split('T')[0])
          .filter('end_time', 'is', null)
          .maybeSingle();

      if (sessionData == null) {
        error.value = 'No active session found';
        return false;
      }

      // Update attendance record
      await _supabase
          .from('attendance_records')
          .update({
            'status': 'present',
            'present': true,
            'finalized': true,
            'finalized_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentData['id'])
          .eq('session_id', sessionData['id']);

      // Clear any existing errors
      error.value = '';
      return true;
    } catch (e) {
      debugPrint('Error verifying passcode: $e');
      error.value = 'Failed to verify passcode';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 