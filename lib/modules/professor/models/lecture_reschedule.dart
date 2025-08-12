class LectureReschedule {
  final String id;
  final String originalScheduleId;
  final String courseId;
  final String instructorId;
  final DateTime originalDateTime;
  final DateTime rescheduledDateTime;
  final String classroom;
  final DateTime expiryDate;
  final DateTime createdAt;

  LectureReschedule({
    required this.id,
    required this.originalScheduleId,
    required this.courseId,
    required this.instructorId,
    required this.originalDateTime,
    required this.rescheduledDateTime,
    required this.classroom,
    required this.expiryDate,
    required this.createdAt,
  });

  factory LectureReschedule.fromMap(Map<String, dynamic> map) {
    return LectureReschedule(
      id: map['id'],
      originalScheduleId: map['original_schedule_id'],
      courseId: map['course_id'],
      instructorId: map['instructor_id'],
      originalDateTime: DateTime.parse(map['original_datetime']),
      rescheduledDateTime: DateTime.parse(map['rescheduled_datetime']),
      classroom: map['classroom'],
      expiryDate: DateTime.parse(map['expiry_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_schedule_id': originalScheduleId,
      'course_id': courseId,
      'instructor_id': instructorId,
      'original_datetime': originalDateTime.toIso8601String(),
      'rescheduled_datetime': rescheduledDateTime.toIso8601String(),
      'classroom': classroom,
      'expiry_date': expiryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
} 