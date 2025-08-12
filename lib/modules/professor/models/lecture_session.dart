class LectureSession {
  final String id;
  final String scheduleId;
  final String courseId;
  final String instructorId;
  final String courseCode;
  final String courseName;
  final String classroom;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRescheduled;
  final String? rescheduleId;
  final bool finalized;
  final String? startQr;
  final String? passcode;

  LectureSession({
    required this.id,
    required this.scheduleId,
    required this.courseId,
    required this.instructorId,
    required this.courseCode,
    required this.courseName,
    required this.classroom,
    required this.startTime,
    required this.endTime,
    this.isRescheduled = false,
    this.rescheduleId,
    this.finalized = false,
    this.startQr,
    this.passcode,
  });

  factory LectureSession.fromJson(Map<String, dynamic> json) {
    return LectureSession(
      id: json['id'] ?? '',
      scheduleId: json['schedule_id'] ?? '',
      courseId: json['course_id'] ?? '',
      instructorId: json['instructor_id'] ?? '',
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      classroom: json['classroom'] ?? '',
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : DateTime.now(),
      isRescheduled: json['is_rescheduled'] ?? false,
      rescheduleId: json['reschedule_id'],
      finalized: json['finalized'] ?? false,
      startQr: json['start_qr'],
      passcode: json['passcode'],
    );
  }

  factory LectureSession.fromMap(Map<String, dynamic> map) {
    return LectureSession(
      id: map['id'] ?? '',
      scheduleId: map['schedule_id'] ?? '',
      courseId: map['course_id'] ?? '',
      instructorId: map['instructor_id'] ?? '',
      courseCode: map['course_code'] ?? '',
      courseName: map['course_name'] ?? '',
      classroom: map['classroom'] ?? '',
      startTime: map['start_time'] != null ? DateTime.parse(map['start_time']) : DateTime.now(),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : DateTime.now(),
      isRescheduled: map['is_rescheduled'] ?? false,
      rescheduleId: map['reschedule_id'],
      finalized: map['finalized'] ?? false,
      startQr: map['start_qr'],
      passcode: map['passcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'course_id': courseId,
      'instructor_id': instructorId,
      'course_code': courseCode,
      'course_name': courseName,
      'classroom': classroom,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_rescheduled': isRescheduled,
      'reschedule_id': rescheduleId,
      'finalized': finalized,
      'start_qr': startQr,
      'passcode': passcode,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  LectureSession copyWith({
    String? id,
    String? scheduleId,
    String? courseId,
    String? instructorId,
    String? courseCode,
    String? courseName,
    String? classroom,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRescheduled,
    String? rescheduleId,
    bool? finalized,
    String? startQr,
    String? passcode,
  }) {
    return LectureSession(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      courseId: courseId ?? this.courseId,
      instructorId: instructorId ?? this.instructorId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      classroom: classroom ?? this.classroom,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRescheduled: isRescheduled ?? this.isRescheduled,
      rescheduleId: rescheduleId ?? this.rescheduleId,
      finalized: finalized ?? this.finalized,
      startQr: startQr ?? this.startQr,
      passcode: passcode ?? this.passcode,
    );
  }
} 