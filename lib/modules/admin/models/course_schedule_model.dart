class CourseSchedule {
  final String id;
  final String assignmentId;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  // Additional fields for UI display
  String? courseCode;
  String? courseName;
  String? instructorName;

  CourseSchedule({
    required this.id,
    required this.assignmentId,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.courseCode,
    this.courseName,
    this.instructorName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'assignment_id': assignmentId,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    return CourseSchedule(
      id: map['id'] ?? '',
      assignmentId: map['assignment_id'] ?? '',
      classroom: map['classroom'] ?? '',
      dayOfWeek: map['day_of_week'] ?? 1,
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      courseCode: map['assignment']?['course']?['code'],
      courseName: map['assignment']?['course']?['name'],
      instructorName: map['assignment']?['instructor']?['name'],
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