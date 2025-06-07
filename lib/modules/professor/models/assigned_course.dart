class Course {
  final String id;
  final String code;
  final String name;
  final int credits;
  final int semester;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      credits: json['credits'],
      semester: json['semester'],
    );
  }
}

class AssignedCourse {
  final String id;
  final String instructorId;
  final String courseId;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final Course course;

  AssignedCourse({
    required this.id,
    required this.instructorId,
    required this.courseId,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.course,
  });

  factory AssignedCourse.fromJson(Map<String, dynamic> json) {
    return AssignedCourse(
      id: json['id'],
      instructorId: json['instructor_id'],
      courseId: json['course_id'],
      classroom: json['classroom'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      course: Course.fromJson(json['course']),
    );
  }
} 