class Program {
  final String id;
  final String name;
  final String code;
  final int duration;
  final int totalSemesters;
  String programType;  // Changed from final to allow modification

  Program({
    required this.id,
    required this.name,
    required this.code,
    required this.duration,
    required this.totalSemesters,
    required this.programType,
  }) {
    // Ensure programType is valid, default to 'BTech' if not
    if (!programTypes.contains(programType)) {
      programType = 'BTech';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'duration': duration,
      'total_semesters': totalSemesters,
      'program_type': programType,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    // Get the program type from the map, defaulting to 'BTech' if null
    String type = map['program_type'] ?? 'BTech';
    
    // Ensure the program type is valid, default to 'BTech' if not
    if (!programTypes.contains(type)) {
      type = 'BTech';
    }

    return Program(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      duration: map['duration'] ?? 0,
      totalSemesters: map['total_semesters'] ?? 8,
      programType: type,
    );
  }

  // Helper method to get program type enum
  static const List<String> programTypes = ['BTech', 'MTech', 'MSc', 'PhD'];
} 