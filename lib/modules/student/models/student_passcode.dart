import 'package:get/get.dart';

class StudentPasscode {
  final String id;
  final String studentId;
  final String courseId;
  final String passcode;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  StudentPasscode({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.passcode,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  factory StudentPasscode.fromMap(Map<String, dynamic> map) {
    return StudentPasscode(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      courseId: map['course_id'] as String,
      passcode: map['passcode'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'passcode': passcode,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
    };
  }
} 