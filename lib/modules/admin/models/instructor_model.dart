class Instructor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> programIds;  // Keep this for UI purposes
  final String role;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.programIds = const [],
    this.role = 'instructor',
  });

  // Convert Instructor to Map for the main instructors table
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  // Create instructor program assignments for the join table
  List<Map<String, dynamic>> createProgramAssignments() {
    return programIds.map((programId) => {
      'instructor_id': id,
      'program_id': programId,
    }).toList();
  }

  // Create Instructor from Map
  factory Instructor.fromMap(Map<String, dynamic> map, {List<String>? programIds}) {
    return Instructor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      programIds: programIds ?? [],
      role: map['role'] ?? 'instructor',
    );
  }

  Instructor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? programIds,
    String? role,
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      programIds: programIds ?? this.programIds,
      role: role ?? this.role,
    );
  }
} 