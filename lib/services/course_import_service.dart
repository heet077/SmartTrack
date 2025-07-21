import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../modules/admin/models/course_model.dart';
import '../modules/admin/models/course_assignment_model.dart';
import '../modules/admin/models/course_schedule_model.dart';
import 'supabase_service.dart';

class CourseImportService {
  static String _extractProgramCode(String batchName) {
    // Convert "BTech Sem-I (ICT + CS)" to "BTECH-ICT-CS"
    final parts = batchName.split(' ');
    if (parts.isEmpty) return '';
    
    String code = parts[0].toUpperCase(); // BTech -> BTECH
    
    // Extract program components from parentheses
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(batchName);
    if (match != null) {
      final components = match.group(1)!.split('+').map((e) => e.trim().toUpperCase());
      code = '$code-${components.join("-")}';
    }
    
    return code;
  }

  static Map<String, int> _parseHoursAndCredits(String format) {
    // Parse format like "3-0-2-4" into theory, tutorial, lab hours and credits
    final parts = format.split('-').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    if (parts.length != 4) return {'theory': 0, 'tutorial': 0, 'lab': 0, 'credits': 0};
    
    return {
      'theory': parts[0],
      'tutorial': parts[1],
      'lab': parts[2],
      'credits': parts[3],
    };
  }

  static int _parseDayOfWeek(String day) {
    final days = {
      'monday': 1,
      'mon': 1,
      'tuesday': 2,
      'tue': 2,
      'wednesday': 3,
      'wed': 3,
      'thursday': 4,
      'thu': 4,
      'friday': 5,
      'fri': 5,
      'saturday': 6,
      'sat': 6,
      'sunday': 7,
      'sun': 7,
    };
    return days[day.toLowerCase()] ?? 0;
  }

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

      // Skip header lines until we find the time slots row
      int currentRow = 0;
      String? currentTimeSlot;

      while (currentRow < rows.length) {
        final row = rows[currentRow];
        final rowStr = row.map((e) => e?.toString() ?? '').join(',');
        print('Processing row $currentRow: $rowStr');

        // Skip empty rows or rows without enough columns
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          currentRow++;
          continue;
        }

        // Check if this is a time slot row
        if (row[0] != null && row[0].toString().trim().contains(':')) {
          currentTimeSlot = row[0].toString().trim();
          print('Found time slot: $currentTimeSlot');
          currentRow++;
          continue;
        }

        // Check if this is a batch row
        if (row.length > 1 && row[1] != null && 
            (row[1].toString().contains('BTech') || 
             row[1].toString().contains('MTech') || 
             row[1].toString().contains('MSc'))) {
          final currentBatch = row[1].toString().trim();
          print('Found batch: $currentBatch');

          // Process courses for this batch
          // Column structure:
          // Time(0), Batch(1), Empty(2)
          // Monday(3-8), Tuesday(9-14), Wednesday(15-20), Thursday(21-26), Friday(27-32)
          for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
            final startCol = 3 + (dayIndex * 6); // Base column for each day
            
            try {
              // Ensure we have enough columns for this day
              if (row.length <= startCol + 5) {
                print('Skipping day $dayIndex - insufficient columns (need ${startCol + 5}, have ${row.length})');
                continue;
              }

              // Extract course details with proper column offsets
              final courseCode = row[startCol]?.toString().trim() ?? '';
              final courseName = row[startCol + 1]?.toString().trim() ?? '';
              final hoursFormat = row[startCol + 2]?.toString().trim() ?? '';
              final courseType = row[startCol + 3]?.toString().trim() ?? '';
              final instructorShortName = row[startCol + 4]?.toString().trim() ?? '';
              final classroom = row[startCol + 5]?.toString().trim() ?? '';

              // Debug column positions
              print('\nProcessing day $dayIndex (columns ${startCol}-${startCol + 5}):');
              print('Column $startCol: Course Code = $courseCode');
              print('Column ${startCol + 1}: Course Name = $courseName');
              print('Column ${startCol + 2}: Hours = $hoursFormat');
              print('Column ${startCol + 3}: Type = $courseType');
              print('Column ${startCol + 4}: Instructor = $instructorShortName');
              print('Column ${startCol + 5}: Classroom = $classroom');

              // Skip if all fields are empty for this day
              if (courseCode.isEmpty && courseName.isEmpty && hoursFormat.isEmpty && 
                  courseType.isEmpty && instructorShortName.isEmpty && classroom.isEmpty) {
                print('Skipping empty course data for day $dayIndex');
                continue;
              }

              // Skip if invalid course code when course code is present
              if (courseCode.isNotEmpty && !_isValidCourseCode(courseCode)) {
                print('Skipping invalid course code for day $dayIndex: $courseCode');
                continue;
              }

              final programCode = _extractProgramCode(currentBatch);
              print('Extracted program code: $programCode');

              // Get program ID
              final programResponse = await SupabaseService.client
                  .from('programs')
                  .select('id')
                  .eq('code', programCode)
                  .maybeSingle();

              if (programResponse != null) {
                final programId = programResponse['id'];
                final hours = _parseHoursAndCredits(hoursFormat);

                // Check if course already exists
                final existingCourse = await SupabaseService.client
                    .from('courses')
                    .select()
                    .eq('code', courseCode)
                    .maybeSingle();

                String courseId;
                if (existingCourse != null) {
                  courseId = existingCourse['id'];
                } else {
                  // Create new course
                  final course = Course(
                    id: '',
                    code: courseCode,
                    name: courseName,
                    credits: hours['credits'] ?? 0,
                    programId: programId,
                    semester: _extractSemester(currentBatch),
                    theoryHours: hours['theory'] ?? 0,
                    tutorialHours: hours['tutorial'] ?? 0,
                    labHours: hours['lab'] ?? 0,
                    courseType: _determineCourseType(courseType),
                  );

                  final courseResponse = await SupabaseService.client
                      .from('courses')
                      .upsert(course.toMap())
                      .select()
                      .single();

                  courseId = courseResponse['id'];
                }

                if (instructorShortName.isNotEmpty) {
                  // Get instructor
                  final instructorResponse = await SupabaseService.client
                      .from('instructors')
                      .select()
                      .eq('short_name', instructorShortName)
                      .maybeSingle();

                  if (instructorResponse != null) {
                    final instructorId = instructorResponse['id'];

                    // Create or update course assignment
                    final assignment = {
                      'instructor_id': instructorId,
                      'course_id': courseId,
                      'created_at': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                    };

                    final assignmentResponse = await SupabaseService.client
                        .from('instructor_course_assignments')
                        .upsert(assignment)
                        .select()
                        .single();

                    final assignmentId = assignmentResponse['id'];

                    // Parse time slot
                    if (currentTimeSlot != null) {
                      final times = currentTimeSlot.split('-').map((t) => t.trim()).toList();
                      if (times.length == 2) {
                        // Create schedule slot with correct day
                        final scheduleSlot = {
                          'assignment_id': assignmentId,
                          'classroom': classroom,
                          'day_of_week': dayIndex + 1, // 1=Monday, 2=Tuesday, etc.
                          'start_time': times[0],
                          'end_time': times[1],
                          'created_at': DateTime.now().toIso8601String(),
                          'updated_at': DateTime.now().toIso8601String(),
                        };

                        await SupabaseService.client
                            .from('course_schedule_slots')
                            .upsert(scheduleSlot)
                            .select()
                            .single();

                        print('Successfully processed course: $courseCode for day ${dayIndex + 1}');
                      }
                    }
                  } else {
                    print('Instructor not found: $instructorShortName');
                  }
                }
              } else {
                print('Program not found: $programCode');
              }
            } catch (e) {
              print('Error processing course for day $dayIndex: $e');
            }
          }
        }
        currentRow++;
      }

      print('Import completed successfully');
    } catch (e) {
      print('Error during import: $e');
      throw 'Failed to import timetable: $e';
    }
  }

  static int _extractSemester(String batchName) {
    final match = RegExp(r'Sem-(\w+)').firstMatch(batchName);
    if (match != null) {
      final romanNumeral = match.group(1) ?? 'I';
      return _romanToInt(romanNumeral);
    }
    return 1;
  }

  static int _romanToInt(String roman) {
    final values = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
    };
    return values[roman] ?? 1;
  }

  // Expected CSV columns:
  // Program Code, Course Code, Course Name, Credits, Semester, Theory Hours, Tutorial Hours, Lab Hours, Course Type,
  // Instructor Email, Classroom, Day (Mon/Tue/etc), Start Time (HH:mm), End Time (HH:mm)
  
  static Future<void> importCoursesWithAssignments(String filePath) async {
    try {
      print('Starting course import from file: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        throw 'File not found: $filePath';
      }

      final input = await file.readAsString();
      print('File contents read successfully');
      final rows = const CsvToListConverter().convert(input);
      print('CSV converted to rows. Total rows: ${rows.length}');

      if (rows.isEmpty) {
        throw 'CSV file is empty';
      }

      print('Header row: ${rows[0]}');
      
      // Skip header row
      for (var i = 1; i < rows.length; i++) {
        print('\nProcessing row $i');
        final row = rows[i];
        if (row.length < 14) {
          print('Skipping invalid row $i: insufficient columns (${row.length} columns)');
          print('Row data: $row');
          continue;
        }

        // Get program ID from program code
        final programCode = row[0]?.toString().trim() ?? '';
        print('Looking up program with code: $programCode');
        if (programCode.isEmpty) {
          print('Skipping row $i: no program code');
          continue;
        }

        try {
          final programResponse = await SupabaseService.client
              .from('programs')
              .select('id')
              .eq('code', programCode)
              .single();
          
          print('Program lookup response: $programResponse');

          if (programResponse == null) {
            print('Skipping row $i: program not found with code $programCode');
            continue;
          }

          final programId = programResponse['id'] as String;
          print('Found program ID: $programId');

          final courseCode = row[1]?.toString().trim() ?? '';
          if (courseCode.isEmpty) {
            print('Skipping row $i: no course code');
            continue;
          }

          // 1. Create or get course
          final course = Course(
            id: '',
            code: courseCode,
            name: row[2]?.toString().trim() ?? '',
            credits: int.tryParse(row[3]?.toString().trim() ?? '') ?? 0,
            programId: programId,
            semester: int.tryParse(row[4]?.toString().trim() ?? '') ?? 1,
            theoryHours: int.tryParse(row[5]?.toString().trim() ?? '') ?? 0,
            tutorialHours: int.tryParse(row[6]?.toString().trim() ?? '') ?? 0,
            labHours: int.tryParse(row[7]?.toString().trim() ?? '') ?? 0,
            courseType: _determineCourseType(row[8]?.toString().trim() ?? ''),
          );

          print('Attempting to create/update course: ${course.toMap()}');

          final courseResponse = await SupabaseService.client
              .from('courses')
              .upsert(course.toMap())
              .select()
              .single();
          
          print('Course upsert response: $courseResponse');
          final courseId = courseResponse['id'] as String;
          print('Course ID: $courseId');

          // 2. Get or create instructor
          final instructorEmail = row[9]?.toString().trim() ?? '';
          print('Looking up instructor with email: $instructorEmail');
          if (instructorEmail.isEmpty) {
            print('Skipping row $i: no instructor email');
            continue;
          }

          try {
            final instructorResponse = await SupabaseService.client
                .from('instructors')
                .select()
                .eq('email', instructorEmail)
                .single();
            
            print('Instructor lookup response: $instructorResponse');

            if (instructorResponse == null) {
              print('Skipping row $i: instructor not found with email $instructorEmail');
              continue;
            }

            final instructorId = instructorResponse['id'] as String;
            print('Found instructor ID: $instructorId');

            // 3. Create course assignment
            final assignment = {
              'instructor_id': instructorId,
              'course_id': courseId,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };

            print('Creating course assignment: $assignment');

            final assignmentResponse = await SupabaseService.client
                .from('instructor_course_assignments')
                .upsert(assignment)
                .select()
                .single();
            
            print('Assignment creation response: $assignmentResponse');
            final assignmentId = assignmentResponse['id'] as String;
            print('Assignment ID: $assignmentId');

            // 4. Create schedule slot
            final classroom = row[10]?.toString().trim() ?? '';
            final dayOfWeek = _parseDayOfWeek(row[11]?.toString().trim() ?? '');
            final startTime = row[12]?.toString().trim() ?? '';
            final endTime = row[13]?.toString().trim() ?? '';

            if (classroom.isNotEmpty && dayOfWeek > 0 && startTime.isNotEmpty && endTime.isNotEmpty) {
              final scheduleSlot = {
                'assignment_id': assignmentId,
                'classroom': classroom,
                'day_of_week': dayOfWeek,
                'start_time': startTime,
                'end_time': endTime,
              };

              print('Creating schedule slot: $scheduleSlot');

              final scheduleResponse = await SupabaseService.client
                  .from('course_schedule_slots')
                  .upsert(scheduleSlot)
                  .select()
                  .single();
              
              print('Schedule slot creation response: $scheduleResponse');
            } else {
              print('Skipping schedule slot creation due to missing data:');
              print('Classroom: $classroom');
              print('Day of week: $dayOfWeek');
              print('Start time: $startTime');
              print('End time: $endTime');
            }
          } catch (e) {
            print('Error processing instructor: $e');
            continue;
          }
        } catch (e) {
          print('Error processing program: $e');
          continue;
        }
      }
      print('Course import completed successfully');
    } catch (e) {
      print('Error during course import: $e');
      throw 'Failed to import courses with assignments: ${e.toString()}';
    }
  }

  static Future<void> importCourseWithAssignment(
    Map<String, dynamic> courseData,
    String instructorShortName,
    String classroom,
    String day,
    String startTime,
    String endTime
  ) async {
    try {
      // Get program ID from program code
      final programResponse = await SupabaseService.client
          .from('programs')
          .select('id')
          .eq('code', courseData['program_id'])
          .single();

      if (programResponse == null) {
        print('Program not found with code ${courseData['program_id']}');
        return;
      }

      final programId = programResponse['id'] as String;
      courseData['program_id'] = programId;

      // Create or update course
      final courseResponse = await SupabaseService.client
          .from('courses')
          .upsert(courseData)
          .select()
          .single();
      
      final courseId = courseResponse['id'] as String;

      // Get instructor ID by short name
      final instructorResponse = await SupabaseService.client
          .from('instructors')
          .select()
          .eq('short_name', instructorShortName)
          .single();

      if (instructorResponse == null) {
        print('Instructor not found with short name $instructorShortName');
        return;
      }

      final instructorId = instructorResponse['id'] as String;

      // Create course assignment
      final assignment = {
        'instructor_id': instructorId,
        'course_id': courseId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final assignmentResponse = await SupabaseService.client
          .from('instructor_course_assignments')
          .upsert(assignment)
          .select()
          .single();

      final assignmentId = assignmentResponse['id'] as String;

      // Create schedule slot
      final dayOfWeek = _getDayOfWeek(day);
      
      final scheduleSlot = {
        'assignment_id': assignmentId,
        'classroom': classroom,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };

      await SupabaseService.client
          .from('course_schedule_slots')
          .upsert(scheduleSlot)
          .select()
          .single();

      print('Successfully imported course ${courseData['code']} with assignment');
    } catch (e) {
      print('Error importing course with assignment: $e');
      rethrow;
    }
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
    
    return 'core'; // Default to core
  }

  static int _getDayOfWeek(String day) {
    final days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7
    };
    return days[day] ?? 1;
  }

  static bool _isValidCourseCode(String code) {
    // Check if the code looks like a course code (e.g., IT101, MA201, etc.)
    // and not a misaligned column value
    return RegExp(r'^[A-Z]{2,3}[0-9]{3,4}$').hasMatch(code) ||
           RegExp(r'^[A-Z]{2,3}-[0-9]{3,4}$').hasMatch(code);
  }
} 