class CourseSchedule {
  final String id;
  final String assignmentId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String classroom;
  final String? courseId;
  final String? courseCode;
  final String? courseName;
  final String? instructorId;
  final String? instructorName;

  CourseSchedule({
    required this.id,
    required this.assignmentId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    this.courseId,
    this.courseCode,
    this.courseName,
    this.instructorId,
    this.instructorName,
  });

  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    final assignment = map['instructor_course_assignments'] as Map<String, dynamic>?;
    final course = assignment?['courses'] as Map<String, dynamic>?;
    final instructor = assignment?['instructors'] as Map<String, dynamic>?;

    return CourseSchedule(
      id: map['id'] as String,
      assignmentId: map['assignment_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classroom: map['classroom'] as String,
      courseId: course?['id'] as String?,
      courseCode: course?['code'] as String?,
      courseName: course?['name'] as String?,
      instructorId: instructor?['id'] as String?,
      instructorName: instructor?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'classroom': classroom,
    };
  }

  String get dayName {
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      default: return 'Unknown';
    }
  }
} 