import '../../auth/models/user_model.dart';

class Student extends User {
  final String registrationNumber;
  final String programId;
  final int semester;
  final String? department;
  final String? phoneNumber;
  final String? programName;

  Student({
    required super.id,
    required super.email,
    required this.registrationNumber,
    required this.programId,
    required this.semester,
    super.name,
    super.profileImage,
    this.department,
    this.phoneNumber,
    this.programName,
  }) : super(role: 'student');

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'registration_number': registrationNumber,
      'program_id': programId,
      'semester': semester,
      'department': department,
      'phone_number': phoneNumber,
      'program_name': programName,
    });
    return map;
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      profileImage: map['profile_image'],
      registrationNumber: map['registration_number'] ?? '',
      programId: map['program_id'] ?? '',
      semester: map['semester'] ?? 1,
      department: map['department'],
      phoneNumber: map['phone_number'],
      programName: map['program']?['name'],
    );
  }
} 