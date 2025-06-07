class Student {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String enrollmentNo;
  final String programId;
  final int semester;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.enrollmentNo,
    required this.programId,
    required this.semester,
  });

  // Convert Student to Map
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'enrollment_no': enrollmentNo,
      'program_id': programId,
      'semester': semester,
    };
  }

  // Create Student from Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      enrollmentNo: map['enrollment_no'] ?? '',
      programId: map['program_id'] ?? '',
      semester: map['semester'] ?? 1,
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? enrollmentNo,
    String? programId,
    int? semester,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      programId: programId ?? this.programId,
      semester: semester ?? this.semester,
    );
  }
} 