class Course {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String programId;
  final int semester;
  final int? theoryHours;
  final int? tutorialHours;
  final int? labHours;
  final String? courseType;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.programId,
    required this.semester,
    this.theoryHours = 0,
    this.tutorialHours = 0,
    this.labHours = 0,
    this.courseType = 'core',
  });

  // Convert Course to Map
  Map<String, dynamic> toMap() {
    final map = {
      'code': code,
      'name': name,
      'credits': credits,
      'program_id': programId,
      'semester': semester,
      'theory_hours': theoryHours,
      'tutorial_hours': tutorialHours,
      'lab_hours': labHours,
      'course_type': courseType,
    };

    // Only include ID if it's not empty
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  // Create Course from Map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      credits: map['credits'] ?? 0,
      programId: map['program_id'] ?? '',
      semester: map['semester'] ?? 1,
      theoryHours: map['theory_hours'],
      tutorialHours: map['tutorial_hours'],
      labHours: map['lab_hours'],
      courseType: map['course_type'],
    );
  }

  // Copy with method
  Course copyWith({
    String? id,
    String? code,
    String? name,
    int? credits,
    String? programId,
    int? semester,
    int? theoryHours,
    int? tutorialHours,
    int? labHours,
    String? courseType,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      programId: programId ?? this.programId,
      semester: semester ?? this.semester,
      theoryHours: theoryHours ?? this.theoryHours,
      tutorialHours: tutorialHours ?? this.tutorialHours,
      labHours: labHours ?? this.labHours,
      courseType: courseType ?? this.courseType,
    );
  }

  // Get display name for course type
  String get courseTypeDisplay {
    switch (courseType?.toLowerCase() ?? 'core') {
      case 'core':
        return 'Core';
      case 'technical_elective':
        return 'Technical Elective';
      case 'open_elective':
        return 'Open Elective';
      case 'science_elective':
        return 'Science Elective';
      case 'mnc_elective':
        return 'MnC Elective';
      case 'ict_technical_elective':
        return 'ICT Technical Elective';
      case 'hasse':
        return 'HASSE';
      case 'general_elective_technical':
        return 'General Elective (Technical)';
      case 'general_elective_maths':
        return 'General Elective (Maths)';
      case 'ves_elective':
        return 'VES Elective';
      case 'wcsp_elective':
        return 'WCSP Elective';
      case 'ml_elective':
        return 'ML Elective';
      case 'ss_elective':
        return 'SS Elective';
      default:
        return 'Core';
    }
  }

  // Get list of available course types
  static List<String> get courseTypes => [
    'core',
    'technical_elective',
    'open_elective',
    'science_elective',
    'mnc_elective',
    'ict_technical_elective',
    'hasse',
    'general_elective_technical',
    'general_elective_maths',
    'ves_elective',
    'wcsp_elective',
    'ml_elective',
    'ss_elective',
  ];

  // Get list of course type display names
  static List<String> get courseTypeDisplays => [
    'Core',
    'Technical Elective',
    'Open Elective',
    'Science Elective',
    'MnC Elective',
    'ICT Technical Elective',
    'HASSE',
    'General Elective (Technical)',
    'General Elective (Maths)',
    'VES Elective',
    'WCSP Elective',
    'ML Elective',
    'SS Elective',
  ];

  // Get hours format (e.g. "3-1-2")
  String get hoursFormat => '${theoryHours ?? 0}-${tutorialHours ?? 0}-${labHours ?? 0}';

  // Get full credit format (e.g. "3-1-2-4")
  String get creditFormat => '${hoursFormat}-$credits';
} 