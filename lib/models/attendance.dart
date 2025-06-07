class Attendance {
  final String id;
  final String courseId;
  final String studentId;
  final DateTime date;
  final bool isPresent;

  Attendance({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.date,
    required this.isPresent,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      studentId: json['student_id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isPresent: json['is_present'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'student_id': studentId,
      'date': date.toIso8601String(),
      'is_present': isPresent,
    };
  }
}

class Student {
  final String id;
  final String name;
  final String enrollmentNo;
  final String email;
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.enrollmentNo,
    required this.email,
    this.isPresent = false,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      enrollmentNo: json['enrollment_no'] ?? '',
      email: json['email'] ?? '',
    );
  }
} 