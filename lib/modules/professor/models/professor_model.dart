import '../../auth/models/user_model.dart';
import './assigned_course.dart';

class Professor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? program;
  final String role;

  Professor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.program,
    this.role = 'instructor',
  });

  Professor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? program,
    String? role,
  }) {
    return Professor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      program: program ?? this.program,
      role: role ?? this.role,
    );
  }

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      program: json['program'],
      role: json['role'] ?? 'instructor',
    );
  }
}

class AssignedCourse {
  final String id;
  final String courseId;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final Course course;

  AssignedCourse({
    required this.id,
    required this.courseId,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.course,
  });

  factory AssignedCourse.fromJson(Map<String, dynamic> json) {
    return AssignedCourse(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      classroom: json['classroom'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      course: Course.fromJson(json['course'] ?? {}),
    );
  }

  String get dayName {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }
}

class Course {
  final String id;
  final String name;
  final String code;
  final int semester;
  final int credits;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.semester,
    required this.credits,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      semester: json['semester'] ?? 0,
      credits: json['credits'] ?? 0,
    );
  }
} 