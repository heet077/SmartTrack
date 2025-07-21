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

  String get dayName {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }

  factory AssignedCourse.fromJson(Map<String, dynamic> json) {
    // Handle both direct schedule slot data and nested schedule data
    final scheduleData = json['schedule'] != null 
        ? (json['schedule'] as List).first 
        : json;

    return AssignedCourse(
      id: scheduleData['id'],
      instructorId: json['instructor_id'],
      courseId: json['course_id'],
      classroom: scheduleData['classroom'] ?? '',
      dayOfWeek: scheduleData['day_of_week'],
      startTime: scheduleData['start_time'],
      endTime: scheduleData['end_time'],
      course: Course.fromJson(json['course']),
    );
  }
} 