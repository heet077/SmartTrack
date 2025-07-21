import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class StudentPasscode {
  final String studentId;
  final String studentName;
  final String passcode;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isUsed;

  StudentPasscode({
    required this.studentId,
    required this.studentName,
    required this.passcode,
    required this.expiresAt,
    required this.createdAt,
    this.isUsed = false,
  });

  factory StudentPasscode.fromJson(Map<String, dynamic> json) {
    return StudentPasscode(
      studentId: json['student_id'] as String,
      studentName: json['student']['name'] as String,
      passcode: json['passcode'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PasscodeController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> passcodes = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> generatePasscodes({
    required String courseId,
    required List<String> studentIds,
    required int validityMinutes,
  }) async {
    try {
      isLoading.value = true;

      // Get current user (professor)
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated - please log in again');
      }

      // Verify user is a professor for this course
      final professorCheck = await _supabase
          .from('instructors')
          .select('''
            id,
            instructor_course_assignments!inner (
              course_id
            )
          ''')
          .eq('email', user.email as Object)
          .single();

      if (professorCheck == null) {
        throw Exception('Not authorized - instructor not found');
      }

      // Verify professor teaches this course
      final assignments = professorCheck['instructor_course_assignments'] as List;
      if (!assignments.any((a) => a['course_id'] == courseId)) {
        throw Exception('Not authorized - instructor does not teach this course');
      }

      // Get current session
      final sessionCheck = await _supabase
          .from('lecture_sessions')
          .select()
          .eq('course_id', courseId)
          .eq('instructor_id', professorCheck['id'])
          .eq('date', DateTime.now().toIso8601String().split('T')[0])
          .filter('end_time', 'is', null)
          .maybeSingle();

      if (sessionCheck == null) {
        throw Exception('No active session found - please start a session first');
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: validityMinutes));

      // Clear any existing unused passcodes for these students
      await _supabase
          .from('student_passcodes')
          .delete()
          .eq('course_id', courseId)
          .inFilter('student_id', studentIds)
          .eq('is_used', false);

      // Generate and insert new passcodes
      final batch = <Map<String, dynamic>>[];
      for (final studentId in studentIds) {
        batch.add({
          'student_id': studentId,
          'course_id': courseId,
          'passcode': _generatePasscode(),
          'expires_at': expiresAt.toIso8601String(),
          'created_at': now.toIso8601String(),
          'is_used': false,
        });
      }

      // Insert all passcodes in a single batch
      if (batch.isNotEmpty) {
        await _supabase.from('student_passcodes').insert(batch);
      }

      // Load the generated passcodes
      final generatedPasscodes = await _supabase
          .from('student_passcodes')
          .select('''
            *,
            student:students (
              id, name, enrollment_no
            )
          ''')
          .eq('course_id', courseId)
          .eq('is_used', false)
          .gte('expires_at', now.toIso8601String());

      passcodes.value = List<Map<String, dynamic>>.from(generatedPasscodes);

      Get.snackbar(
        'Success',
        'Generated passcodes for ${studentIds.length} students',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      debugPrint('Error generating passcodes: $e');
      
      String errorMessage = 'Failed to generate passcodes';
      if (e.toString().contains('42501')) {
        errorMessage = 'Not authorized to generate passcodes for this course';
      } else if (e.toString().contains('lecture_sessions')) {
        errorMessage = 'No active session found - please start a session first';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  String _generatePasscode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Generates a number between 100000 and 999999
  }

  Future<void> loadPasscodes(String courseId) async {
    try {
      isLoading.value = true;

      final response = await _supabase
          .from('student_passcodes')
          .select('''
            *,
            student:students (
              id, name
            )
          ''')
          .eq('course_id', courseId)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      passcodes.value = (response as List)
          .map((data) => StudentPasscode.fromJson(data)).cast<Map<String, dynamic>>()
          .toList();

    } catch (e) {
      debugPrint('Error loading passcodes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearExpiredPasscodes(String courseId) async {
    try {
      isLoading.value = true;

      await _supabase
          .from('student_passcodes')
          .delete()
          .eq('course_id', courseId)
          .lt('expires_at', DateTime.now().toIso8601String());

      await loadPasscodes(courseId);

      Get.snackbar(
        'Success',
        'Expired passcodes cleared',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      debugPrint('Error clearing expired passcodes: $e');
      Get.snackbar(
        'Error',
        'Failed to clear expired passcodes',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyPasscode({
    required String studentId,
    required String courseId,
    required String passcode,
  }) async {
    try {
      isLoading.value = true;

      // Check if passcode exists and is valid
      final passcodeData = await _supabase
          .from('student_passcodes')
          .select()
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .eq('passcode', passcode)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (passcodeData == null) return false;

      // Mark passcode as used
      await _supabase
          .from('student_passcodes')
          .update({'is_used': true})
          .eq('id', passcodeData['id']);

      // Update attendance record
      await _supabase
          .from('attendance_records')
          .update({
            'status': 'present',
            'present': true,
            'finalized': true,
            'finalized_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentId)
          .eq('session_id', passcodeData['session_id']);

      return true;
    } catch (e) {
      debugPrint('Error verifying passcode: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 