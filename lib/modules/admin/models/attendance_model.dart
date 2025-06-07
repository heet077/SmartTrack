class AttendanceRecord {
  final String id;
  final String courseCode;
  final String courseName;
  final String date;
  final int totalStudents;
  final int presentStudents;
  final List<StudentAttendance> studentRecords;

  AttendanceRecord({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.date,
    required this.totalStudents,
    required this.presentStudents,
    required this.studentRecords,
  });

  double get attendancePercentage => 
    totalStudents > 0 ? (presentStudents / totalStudents * 100) : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'date': date,
      'totalStudents': totalStudents,
      'presentStudents': presentStudents,
      'studentRecords': studentRecords.map((x) => x.toMap()).toList(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      courseCode: map['courseCode'],
      courseName: map['courseName'],
      date: map['date'],
      totalStudents: map['totalStudents'],
      presentStudents: map['presentStudents'],
      studentRecords: List<StudentAttendance>.from(
        map['studentRecords']?.map((x) => StudentAttendance.fromMap(x)),
      ),
    );
  }
}

class StudentAttendance {
  final String studentId;
  final String studentName;
  final bool isPresent;
  final String? remarks;

  StudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.isPresent,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'isPresent': isPresent,
      'remarks': remarks,
    };
  }

  factory StudentAttendance.fromMap(Map<String, dynamic> map) {
    return StudentAttendance(
      studentId: map['studentId'],
      studentName: map['studentName'],
      isPresent: map['isPresent'],
      remarks: map['remarks'],
    );
  }
} 