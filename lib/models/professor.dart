class Professor {
  final String id;
  final String name;
  final String email;
  final List<CourseAssignment> assignedCourses;

  Professor({
    required this.id,
    required this.name,
    required this.email,
    required this.assignedCourses,
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    List<CourseAssignment> courses = [];
    if (json['course_assignments'] != null) {
      courses = (json['course_assignments'] as List)
          .map((assignment) => CourseAssignment.fromJson(assignment))
          .toList();
    }

    return Professor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      assignedCourses: courses,
    );
  }
}

class Course {
  final String id;
  final String name;
  final String code;
  final String semester;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.semester,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      semester: json['semester'] ?? '',
    );
  }
}

class CourseAssignment {
  final Course course;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  CourseAssignment({
    required this.course,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  String get dayName {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }

  factory CourseAssignment.fromJson(Map<String, dynamic> json) {
    return CourseAssignment(
      course: Course.fromJson(json['course']),
      classroom: json['classroom'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }
} 