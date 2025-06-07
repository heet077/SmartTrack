class CourseAssignment {
  final String id;
  final String instructorId;
  final String courseId;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  // Additional fields for UI display
  String? instructorName;
  String? courseName;
  String? courseCode;

  CourseAssignment({
    required this.id,
    required this.instructorId,
    required this.courseId,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.instructorName,
    this.courseName,
    this.courseCode,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'instructor_id': instructorId,
      'course_id': courseId,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory CourseAssignment.fromMap(Map<String, dynamic> map) {
    return CourseAssignment(
      id: map['id'] ?? '',
      instructorId: map['instructor_id'] ?? '',
      courseId: map['course_id'] ?? '',
      classroom: map['classroom'] ?? '',
      dayOfWeek: map['day_of_week'] ?? 1,
      startTime: map['start_time'] ?? '00:00',
      endTime: map['end_time'] ?? '00:00',
      instructorName: map['instructors']?['name'],
      courseName: map['courses']?['name'],
      courseCode: map['courses']?['code'],
    );
  }

  static List<String> get daysOfWeek => [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get dayName => daysOfWeek[dayOfWeek - 1];
} 