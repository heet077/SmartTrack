import 'dart:io';
import 'package:csv/csv.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';
import '../modules/admin/models/course_model.dart';
import '../modules/admin/models/course_assignment_model.dart';
import '../modules/admin/models/course_schedule_model.dart';
import 'supabase_service.dart';

class CourseImportService {
  static final _uuid = Uuid();

  /// Imports timetable data from a CSV file.
  static Future<void> importDAIICTTimetable(String filePath) async {
    try {
      print('Starting DAIICT timetable import from file: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        throw 'File not found: $filePath';
      }

      // Read file content
      final input = await file.readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(input, shouldParseNumbers: false);
      print('Total rows: ${rows.length}');

      String? currentTimeSlot;
      String currentDay = '';
      int currentRow = 0;
      bool foundFirstDay = false;

      // First find the header row that contains "Time,Batch,,Monday"
      while (currentRow < rows.length && !foundFirstDay) {
        final row = rows[currentRow];
        if (row.length >= 4) {
          final cell0 = row[0]?.toString().trim() ?? '';
          final cell3 = row[3]?.toString().trim().toLowerCase() ?? '';
          
          if (cell0.toLowerCase() == 'time' && cell3 == 'monday') {
            currentDay = 'Monday';
            foundFirstDay = true;
            print('\n==========================================');
            print('Found first day section: Monday');
            print('==========================================\n');
            currentRow++;
            continue;
          }
        }
        currentRow++;
      }

      if (!foundFirstDay) {
        throw 'Could not find start of timetable (Monday section)';
      }

      // Process rows
      while (currentRow < rows.length) {
        final row = rows[currentRow];

        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          currentRow++;
          continue;
        }

        // Check for day changes
        if (row.length >= 4) {
          final dayCell = row[3]?.toString().trim().toLowerCase() ?? '';
          switch (dayCell) {
            case 'tuesday': 
              currentDay = 'Tuesday';
              print('\n==========================================');
              print('Found new day section: Tuesday');
              print('==========================================\n');
              currentRow++;
              continue;
            case 'wednesday':
              currentDay = 'Wednesday';
              print('\n==========================================');
              print('Found new day section: Wednesday');
              print('==========================================\n');
              currentRow++;
              continue;
            case 'thursday':
              currentDay = 'Thursday';
              print('\n==========================================');
              print('Found new day section: Thursday');
              print('==========================================\n');
              currentRow++;
              continue;
            case 'friday':
              currentDay = 'Friday';
              print('\n==========================================');
              print('Found new day section: Friday');
              print('==========================================\n');
              currentRow++;
              continue;
          }
        }

        // Get time slot from first column if present
        if (row[0] != null && row[0].toString().trim().isNotEmpty) {
          currentTimeSlot = row[0].toString().trim();
        }

        // Skip if no time slot
        if (currentTimeSlot == null) {
          currentRow++;
          continue;
        }

        // Process each batch's course data
        for (int i = 1; i < row.length - 5; i += 6) {
          final batch = row[i]?.toString().trim() ?? '';
          if (batch.isEmpty) continue;

          final courseCode = row[i + 1]?.toString().trim() ?? '';
          final courseName = row[i + 2]?.toString().trim() ?? '';
          final hoursFormat = row[i + 3]?.toString().trim() ?? '';
          final courseType = row[i + 4]?.toString().trim() ?? '';
          final instructor = row[i + 5]?.toString().trim() ?? '';
          final classroom = row[i + 6]?.toString().trim() ?? '';

          if (courseCode.isEmpty || instructor.isEmpty) continue;

          print('\nProcessing course for batch: $batch');
              print('Course Code: $courseCode');
              print('Course Name: $courseName');
              print('Hours Format: $hoursFormat');
              print('Course Type: $courseType');
          print('Instructor: $instructor');
              print('Classroom: $classroom');
          print('Time Slot: $currentTimeSlot');
          print('Day: $currentDay');

          try {
            // Extract program code from batch
            final programCode = _extractProgramCode(batch);
              print('Extracted program code: $programCode');

            // Create or get course
            final courseId = await _getOrCreateCourse(
                    code: courseCode,
                    name: courseName,
              hoursFormat: hoursFormat,
              type: courseType,
              programCode: programCode,
              batch: batch,
            );

            // Create or get instructor
            final instructorId = await _getOrCreateInstructor(instructor);

            // Create assignment
            final assignmentId = await _createAssignment(
              courseId: courseId,
              instructorId: instructorId,
            );

            // Create schedule slot
            final times = currentTimeSlot.split(' - ');
                      if (times.length == 2) {
              await _createScheduleSlot(
                assignmentId: assignmentId,
                dayOfWeek: _getDayOfWeek(currentDay),
                startTime: times[0],
                endTime: times[1],
                classroom: classroom,
              );
            }
          } catch (e) {
            print('Error processing course $courseCode: $e');
            // Continue with next course instead of stopping the entire import
            continue;
          }
        }

        currentRow++;
      }

      print('\nImport completed successfully');
      
      // Print summary
      final assignments = await SupabaseService.client
          .from('instructor_course_assignments')
          .select();
      
      final scheduleSlots = await SupabaseService.client
          .from('course_schedule_slots')
          .select();
      
      print('\nSummary:');
      print('Total assignments created: ${assignments.length}');
      print('Total schedule slots created: ${scheduleSlots.length}');
    } catch (e) {
      print('Error during import: $e');
      rethrow;
    }
  }

  /// Helper method to safely convert a value to a string
  static String _safeToString(dynamic value) {
    if (value == null) return '';
    try {
      return value.toString().trim();
    } catch (e) {
      print('Error converting value to string: $value, error: $e');
      return '';
    }
  }

  /// Helper method to get program_id based on program short name
  static Future<String?> _getProgramId(String programShortName) async {
    try {
      if (programShortName.isEmpty) {
        print('Program short name is empty');
        return null;
      }
      final normalizedProgram = _normalizeProgram(programShortName);
      final response = await SupabaseService.client
          .from('programs')
          .select('id')
          .eq('name', normalizedProgram)
          .maybeSingle();
      return response?['id'];
    } catch (e) {
      print('Error fetching program ID for $programShortName: $e');
      return null;
    }
  }

  /// Helper method to get instructor_id based on short_name
  static Future<String?> _getInstructorId(String instructorShortName) async {
    try {
      if (instructorShortName.isEmpty) return null;
      final shortNames = instructorShortName.split('/').map((s) => s.trim()).toList();
      final response = await SupabaseService.client
          .from('instructors')
          .select('id')
          .inFilter('short_name', shortNames)
          .maybeSingle();
      return response?['id'];
    } catch (e) {
      print('Error fetching instructor ID for $instructorShortName: $e');
      return null;
    }
  }

  /// Parse credits from string (e.g., "3-0-0-3" or "4.5")
  static int _parseCredits(String creditStr) {
    if (creditStr.isEmpty) return 3;
    try {
      if (creditStr.contains('-')) {
        final parts = creditStr.split('-');
        return int.parse(parts.last.trim());
      }
      return double.parse(creditStr).round();
    } catch (e) {
      print('Error parsing credits: $creditStr, defaulting to 3');
      return 3;
    }
  }

  /// Parse semester from program string (e.g., "BTech Sem-I" -> 1)
  static int _parseSemester(String programStr) {
    try {
      final match = RegExp(r'Sem-([IVX]+)').firstMatch(programStr);
      if (match != null) {
        final roman = match.group(1)!;
        final values = {'I': 1, 'II': 2, 'III': 3, 'IV': 4, 'V': 5, 'VI': 6, 'VII': 7, 'VIII': 8};
        return values[roman] ?? 1;
      }
      return 1;
    } catch (e) {
      print('Error parsing semester: $programStr, defaulting to 1');
      return 1;
    }
  }

  /// Normalize course type
  static String _normalizeCourseType(String type) {
    final lowercaseType = type.toLowerCase();
    if (lowercaseType.contains('core')) return 'core';
    if (lowercaseType.contains('technical')) return 'technical_elective';
    if (lowercaseType.contains('open')) return 'open_elective';
    if (lowercaseType.contains('science')) return 'science_elective';
    if (lowercaseType.contains('mnc')) return 'mnc_elective';
    if (lowercaseType.contains('ict')) return 'ict_technical_elective';
    if (lowercaseType.contains('general') && lowercaseType.contains('technical')) return 'general_elective_technical';
    if (lowercaseType.contains('general') && lowercaseType.contains('maths')) return 'general_elective_maths';
    if (lowercaseType.contains('ves')) return 'ves_elective';
    if (lowercaseType.contains('wcsp')) return 'wcsp_elective';
    if (lowercaseType.contains('ml')) return 'ml_elective';
    if (lowercaseType.contains('ss')) return 'ss_elective';
    return 'core';
  }

  /// Normalize program name
  static String _normalizeProgram(String programStr) {
    final Map<String, String> map = {
      'BTech Sem-I (ICT + CS)': 'BTech ICT',
      'BTech Sem-I (MnC)': 'BTech MnC',
      'BTech Sem-I (EVD)': 'BTech EVD',
      'BTech Sem-III (ICT + CS)': 'BTech ICT',
      'BTech Sem-III (MnC)': 'BTech MnC',
      'BTech Sem-III (EVD)': 'BTech EVD',
      'BTech Sem-V (ICT + CS)': 'BTech ICT',
      'BTech Sem-V (CS-Only)': 'BTech CS',
      'BTech Sem-V (MnC)': 'BTech MnC',
      'BTech Sem-V (EVD)': 'BTech EVD',
      'BTech Sem-VII (ICT + CS)': 'BTech ICT',
      'BTech Sem-VII (MnC)': 'BTech MnC',
      'MTech Sem-I (ICT-SS)': 'MTech ICT-SS',
      'MTech Sem-I (ICT-ML)': 'MTech ICT-ML',
      'MTech Sem-I (ICT-VLSI&ES)': 'MTech ICT-VLSI&ES',
      'MTech Sem-I (ICT-WCSP)': 'MTech ICT-WCSP',
      'MTech Sem-III (ICT-SS)': 'MTech ICT-SS',
      'MTech Sem-III (ICT-ML)': 'MTech ICT-ML',
      'MTech Sem-III (ICT-VLSI&ES)': 'MTech ICT-VLSI&ES',
      'MTech Sem-III (ICT-WCSP)': 'MTech ICT-WCSP',
      'MSc Sem-I (IT)': 'MSc IT',
      'MSc Sem-I (DS)': 'MSc DS',
      'MSc Sem-I (AA)': 'MSc AA',
      'MSc Sem-III (IT)': 'MSc IT',
      'MSc Sem-III (DS)': 'MSc DS',
    };
    return map[programStr] ?? programStr;
  }

  /// Parse day of week to integer (1=Monday, ..., 5=Friday)
  static int? _parseDayOfWeek(String day) {
    final map = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
    };
    return map[day];
  }

  /// Helper method to extract program code from batch string
  static String _extractProgramCode(String batch) {
    // Extract program type (BTech/MTech/MSc) and specialization from batch name
    final regex = RegExp(r'(BTech|MTech|MSc)\s+Sem-[IVX]+\s*\(([^)]+)\)');
    final match = regex.firstMatch(batch);
    if (match != null) {
      final programType = match.group(1);
      final specialization = match.group(2)?.trim();
      if (programType != null && specialization != null) {
        // Handle special cases first
        if (specialization == 'ICT + CS') {
          return 'BTECH-ICT-CS';
        } else if (specialization == 'MnC') {
          return 'BTECH-MNC';
        } else if (specialization == 'EVD') {
          return 'BTECH-EVD';
        } else if (specialization == 'CS') {
          return 'BTECH-CS';
        } else if (specialization.startsWith('ICT-')) {
          // Handle ICT specializations
          final spec = specialization.substring(4);
          switch (spec) {
            case 'SS':
              return 'MTECH-ICT-SS';
            case 'ML':
              return 'MTECH-ICT-ML';
            case 'VLSI&ES':
              return 'MTECH-ICT-VLSI';
            case 'WCSP':
              return 'MTECH-ICT-WCSP';
            default:
              return '${programType.toUpperCase()}-ICT-${spec.replaceAll(' ', '')}';
          }
        } else if (specialization == 'EC') {
          return 'MTECH-EC';
        } else if (specialization == 'IT') {
          return 'MSC-IT';
        } else if (specialization == 'DS') {
          return 'MSC-DS';
        } else if (specialization == 'AA') {
          return 'MSC-AA';
        }

        // For any other cases, normalize the specialization
        final normalizedSpec = specialization
          .replaceAll('&', 'AND')
          .replaceAll('+', '-')
          .replaceAll(' ', '')
          .toUpperCase();
        return '${programType.toUpperCase()}-$normalizedSpec';
      }
    }
    throw 'Could not extract program code from batch: $batch';
  }

  static String _formatTime(String time) {
    // Convert "8:00" to "08:00:00" for PostgreSQL time format
    final parts = time.split(':');
    if (parts.length != 2) return time;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
  }

  /// Helper method to get day of week integer
  static int _getDayOfWeek(String day) {
    final Map<String, int> days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
    };
    final dayNum = days[day.toLowerCase()];
    if (dayNum == null) {
      print('Warning: Invalid day "$day", defaulting to Monday (1)');
      return 1;
    }
    return dayNum;
  }

  static Future<String> _getOrCreateCourse({
    required String code,
    required String name,
    required String hoursFormat,
    required String type,
    required String programCode,
    required String batch,
  }) async {
    print('Looking up program with code: $programCode');
    
    // Get program ID
      final programResponse = await SupabaseService.client
          .from('programs')
        .select('id, code')
        .or('code.eq.$programCode,code.ilike.$programCode')
        .maybeSingle();

      if (programResponse == null) {
      throw 'Program not found: $programCode. Please ensure the program exists in the database.';
    }

    print('Found program: ${programResponse['code']} (ID: ${programResponse['id']})');
    
    final programId = programResponse['id'];
    final hours = _parseHoursAndCredits(hoursFormat);
    final semester = _extractSemester(batch);

    // Check if course exists
    final existingCourse = await SupabaseService.client
        .from('courses')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (existingCourse != null) {
      final id = existingCourse['id'];
      if (id != null) {
        print('Found existing course: $code (ID: $id)');
        return id.toString();
      }
    }

    // Create new course
    final courseData = {
      'id': _uuid.v4(),
      'code': code,
      'name': name,
      'credits': hours['credits'] ?? 0,
      'program_id': programId,
      'semester': semester,
      'theory_hours': hours['theory'] ?? 0,
      'tutorial_hours': hours['tutorial'] ?? 0,
      'lab_hours': hours['lab'] ?? 0,
      'course_type': _determineCourseType(type),
    };

      final courseResponse = await SupabaseService.client
          .from('courses')
          .upsert(courseData)
          .select()
          .single();
      
    final id = courseResponse['id'];
    if (id == null) throw 'Failed to create course: No ID returned';

    print('Created new course: $code (ID: $id)');
    return id.toString();
  }

  static Future<String> _getOrCreateInstructor(String shortName) async {
    print('Looking up instructor with short name: $shortName');
    
    // Check if instructor exists (case-insensitive)
      final instructorResponse = await SupabaseService.client
          .from('instructors')
          .select()
        .ilike('short_name', shortName)
        .maybeSingle();

    if (instructorResponse != null) {
      final id = instructorResponse['id'];
      if (id != null) {
        print('Found existing instructor: ${instructorResponse['name']} (ID: $id)');
        return id.toString();
      }
    }

    // Try looking up with split short names (e.g., "A/B" -> ["A", "B"])
    if (shortName.contains('/')) {
      final shortNames = shortName.split('/').map((s) => s.trim()).toList();
      for (final name in shortNames) {
        final splitResponse = await SupabaseService.client
            .from('instructors')
            .select()
            .ilike('short_name', name)
            .maybeSingle();

        if (splitResponse != null) {
          final id = splitResponse['id'];
          if (id != null) {
            print('Found existing instructor by split name: ${splitResponse['name']} (ID: $id)');
            return id.toString();
          }
        }
      }
    }

    // If instructor not found, use TBD instructor
    print('Instructor not found with short name: $shortName, using TBD instructor');
    final tbdResponse = await SupabaseService.client
        .from('instructors')
        .select()
        .eq('short_name', 'TBD')
          .single();

    final tbdId = tbdResponse['id'];
    if (tbdId == null) throw 'TBD instructor not found in database';
    
    print('Using TBD instructor (ID: $tbdId) for $shortName');
    return tbdId.toString();
  }

  static Future<String> _createAssignment({
    required String courseId,
    required String instructorId,
  }) async {
    print('\nCreating/checking assignment for course $courseId and instructor $instructorId');
    
    // Check if assignment already exists
    final existingAssignment = await SupabaseService.client
        .from('instructor_course_assignments')
        .select()
        .eq('course_id', courseId)
        .eq('instructor_id', instructorId)
        .maybeSingle();

    if (existingAssignment != null) {
      final id = existingAssignment['id'];
      if (id != null) {
        print('Found existing assignment (ID: $id)');
        return id.toString();
      }
    }

    final assignmentData = {
      'id': _uuid.v4(),
        'instructor_id': instructorId,
        'course_id': courseId,
      };

    print('Creating new assignment with data: $assignmentData');
      final assignmentResponse = await SupabaseService.client
          .from('instructor_course_assignments')
        .insert(assignmentData)
          .select()
          .single();

    final id = assignmentResponse['id'];
    if (id == null) throw 'Failed to create assignment: No ID returned';

    print('Created new assignment (ID: $id)');
    return id.toString();
  }

  static Future<void> _createScheduleSlot({
    required String assignmentId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String classroom,
  }) async {
    print('\nCreating schedule slot:');
    print('Assignment ID: $assignmentId');
    print('Day: $dayOfWeek');
    print('Time: $startTime - $endTime');
    print('Classroom: $classroom');

    // Check if slot already exists
    final existingSlot = await SupabaseService.client
        .from('course_schedule_slots')
        .select()
        .eq('assignment_id', assignmentId)
        .eq('day_of_week', dayOfWeek)
        .eq('start_time', _formatTime(startTime))
        .eq('end_time', _formatTime(endTime))
        .eq('classroom', classroom)
        .maybeSingle();

    if (existingSlot != null) {
      print('Schedule slot already exists (ID: ${existingSlot['id']})');
      return;
    }
      
      final scheduleSlot = {
      'id': _uuid.v4(),
        'assignment_id': assignmentId,
        'classroom': classroom,
        'day_of_week': dayOfWeek,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      };

    print('Creating new schedule slot with data: $scheduleSlot');
    try {
      final scheduleResponse = await SupabaseService.client
          .from('course_schedule_slots')
          .insert(scheduleSlot)
          .select()
          .single();

      final id = scheduleResponse['id'];
      if (id != null) {
        print('Created schedule slot (ID: $id)');
      }
    } catch (e) {
      print('Error creating schedule slot: $e');
      throw e;
    }
  }

  static Map<String, int> _parseHoursAndCredits(String format) {
    // Parse formats like "3-0-0-3", "3-0-0", or "1-0-2-2"
    if (format.isEmpty) return {'theory': 0, 'tutorial': 0, 'lab': 0, 'credits': 0};
    final parts = format.split('-').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    if (parts.length < 3) return {'theory': 0, 'tutorial': 0, 'lab': 0, 'credits': 0};
    return {
      'theory': parts[0],
      'tutorial': parts[1],
      'lab': parts[2],
      'credits': parts.length > 3 ? parts[3] : parts[0] + parts[1] + parts[2],
    };
  }

  static int _extractSemester(String batch) {
    // Extract semester from strings like "BTech Sem-I", "MTech Sem-III", etc.
    final regex = RegExp(r'Sem-([IVX]+)');
    final match = regex.firstMatch(batch);
    if (match != null) {
      final romanNumeral = match.group(1);
      if (romanNumeral != null) {
        switch (romanNumeral) {
          case 'I': return 1;
          case 'II': return 2;
          case 'III': return 3;
          case 'IV': return 4;
          case 'V': return 5;
          case 'VI': return 6;
          case 'VII': return 7;
          case 'VIII': return 8;
        }
      }
    }
    throw 'Could not extract semester from batch: $batch';
  }

  static String _determineCourseType(String type) {
    final lowercaseType = type.toLowerCase();
    if (lowercaseType.contains('core')) return 'core';
    if (lowercaseType.contains('technical elective')) return 'technical_elective';
    if (lowercaseType.contains('open elective')) return 'open_elective';
    if (lowercaseType.contains('science elective')) return 'science_elective';
    if (lowercaseType.contains('mnc elective')) return 'mnc_elective';
    if (lowercaseType.contains('ict') && lowercaseType.contains('technical')) return 'ict_technical_elective';
    if (lowercaseType.contains('hasse')) return 'hasse';
    if (lowercaseType.contains('general') && lowercaseType.contains('technical')) return 'general_elective_technical';
    if (lowercaseType.contains('general') && lowercaseType.contains('maths')) return 'general_elective_maths';
    if (lowercaseType.contains('ves')) return 'ves_elective';
    if (lowercaseType.contains('wcsp')) return 'wcsp_elective';
    if (lowercaseType.contains('ml elective')) return 'ml_elective';
    if (lowercaseType.contains('ss elective')) return 'ss_elective';
    return 'core';
  }
} 