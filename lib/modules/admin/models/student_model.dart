class Student {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String enrollmentNo;
  final String programId;
  final int semester;
  final String password;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.enrollmentNo,
    required this.programId,
    required this.semester,
    String? password,
  }) : password = password ?? email;

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
      'password': password,
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
      password: map['password'] ?? map['email'] ?? '',
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
    String? password,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      programId: programId ?? this.programId,
      semester: semester ?? this.semester,
      password: password ?? this.password,
    );
  }
} 