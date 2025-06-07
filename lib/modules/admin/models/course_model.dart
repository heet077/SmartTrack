class Course {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String programId;
  final int semester;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.programId,
    required this.semester,
  });

  // Convert Course to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credits': credits,
      'program_id': programId,
      'semester': semester,
    };
  }

  // Create Course from Map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      code: map['code'] ?? '',
      name: map['name'],
      credits: map['credits'],
      programId: map['program_id'],
      semester: map['semester'],
    );
  }
} 