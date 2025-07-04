class LectureSession {
  final String id;
  final String courseId;
  final DateTime startTime;
  final String? endTime;
  final bool finalized;
  final String? startQr;
  final String? passcode;

  LectureSession({
    required this.id,
    required this.courseId,
    required this.startTime,
    this.endTime,
    this.finalized = false,
    this.startQr,
    this.passcode,
  });

  factory LectureSession.fromJson(Map<String, dynamic> json) {
    return LectureSession(
      id: json['id'],
      courseId: json['course_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'],
      finalized: json['finalized'] ?? false,
      startQr: json['start_qr'],
      passcode: json['passcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime,
      'finalized': finalized,
      'start_qr': startQr,
      'passcode': passcode,
    };
  }
} 