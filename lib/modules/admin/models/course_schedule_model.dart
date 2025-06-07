class CourseSchedule {
  final String id;
  final String courseCode;
  final String courseName;
  final String instructorName;
  final String instructorId;
  final List<String> days;
  final String startTime;
  final String endTime;
  final String room;

  CourseSchedule({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.instructorName,
    required this.instructorId,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  // Convert CourseSchedule to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'instructorName': instructorName,
      'instructorId': instructorId,
      'days': days,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
    };
  }

  // Create CourseSchedule from Map
  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    return CourseSchedule(
      id: map['id'],
      courseCode: map['courseCode'],
      courseName: map['courseName'],
      instructorName: map['instructorName'],
      instructorId: map['instructorId'],
      days: List<String>.from(map['days']),
      startTime: map['startTime'],
      endTime: map['endTime'],
      room: map['room'],
    );
  }
} 