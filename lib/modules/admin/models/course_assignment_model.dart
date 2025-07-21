class CourseAssignment {
  final String id;
  final String instructorId;
  final String courseId;
  final List<ScheduleSlot> scheduleSlots;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional fields for UI display
  String? instructorName;
  String? courseName;
  String? courseCode;

  CourseAssignment({
    required this.id,
    required this.instructorId,
    required this.courseId,
    required this.scheduleSlots,
    this.createdAt,
    this.updatedAt,
    this.instructorName,
    this.courseName,
    this.courseCode,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'instructor_id': instructorId,
      'course_id': courseId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CourseAssignment.fromMap(Map<String, dynamic> map) {
    return CourseAssignment(
      id: map['id'] ?? '',
      instructorId: map['instructor_id'] ?? '',
      courseId: map['course_id'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      scheduleSlots: (map['schedule'] as List<dynamic>?)?.map((slot) => ScheduleSlot.fromMap(slot)).toList() ?? [],
      instructorName: map['instructor']?['name'],
      courseName: map['course']?['name'],
      courseCode: map['course']?['code'],
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
}

class ScheduleSlot {
  final String id;
  final String classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  ScheduleSlot({
    required this.id,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleSlot(
      id: map['id'] ?? '',
      classroom: map['classroom'] ?? '',
      dayOfWeek: map['day_of_week'] ?? 1,
      startTime: map['start_time'] ?? '00:00',
      endTime: map['end_time'] ?? '00:00',
    );
  }

  String get dayName => CourseAssignment.daysOfWeek[dayOfWeek - 1];
} 