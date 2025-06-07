import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://qybnusofqqhxkyptzhbo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5Ym51c29mcXFoeGt5cHR6aGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1MTM0NjUsImV4cCI6MjA2NDA4OTQ2NX0.nv48hNBTlYJDn_yyYqmIeY_W1-NYwBQ4p2I-5t30_1k';
  
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Authentication methods
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Admin Methods
  static Future<Map<String, dynamic>?> getAdminByEmail(String email) async {
    try {
      final response = await client
          .from('admins')
          .select()
          .eq('email', email)
          .single();
      return response;
    } catch (e) {
      print('Error fetching admin: $e');
      return null;
    }
  }

  // Program Methods
  static Future<List<Map<String, dynamic>>> getPrograms() async {
    final response = await client
        .from('programs')
        .select('*, courses(*)');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addProgram({
    required String name,
    required String code,
    required int duration,
  }) async {
    final response = await client
        .from('programs')
        .insert({
          'name': name,
          'code': code,
          'duration': duration,
        })
        .select()
        .single();
    return response;
  }

  // Course Methods
  static Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await client
        .from('courses')
        .select('*, programs(*), course_assignments(*, instructors(*))');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addCourse({
    required String name,
    required String code,
    required String programId,
    required int semester,
    required int credits,
  }) async {
    final response = await client
        .from('courses')
        .insert({
          'name': name,
          'code': code,
          'program_id': programId,
          'semester': semester,
          'credits': credits,
        })
        .select()
        .single();
    return response;
  }

  // Instructor Methods
  static Future<List<Map<String, dynamic>>> getInstructors() async {
    final response = await client
        .from('instructors')
        .select('*, course_assignments(*, courses(*))');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addInstructor({
    required String name,
    required String email,
    String? phone,
    String? department,
  }) async {
    final response = await client
        .from('instructors')
        .insert({
          'name': name,
          'email': email,
          'phone': phone,
          'department': department,
          'role': 'instructor',
        })
        .select()
        .single();
    return response;
  }

  // Student Methods
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final response = await client
        .from('students')
        .select('*, programs(*)');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addStudent({
    required String name,
    required String email,
    required String enrollmentNo,
    required String programId,
    required int semester,
    String? phone,
  }) async {
    final response = await client
        .from('students')
        .insert({
          'name': name,
          'email': email,
          'enrollment_no': enrollmentNo,
          'program_id': programId,
          'semester': semester,
          'phone': phone,
        })
        .select()
        .single();
    return response;
  }

  // Course Assignment (Schedule) Methods
  static Future<List<Map<String, dynamic>>> getCourseAssignments() async {
    final response = await client
        .from('course_assignments')
        .select('*, courses!course_assignments_course_id_fkey(*), instructors(*)');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addCourseAssignment({
    required String instructorId,
    required String courseId,
    required String classroom,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await client
        .from('course_assignments')
        .insert({
          'instructor_id': instructorId,
          'course_id': courseId,
          'classroom': classroom,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
        })
        .select()
        .single();
    return response;
  }

  // Lecture Session Methods
  static Future<List<Map<String, dynamic>>> getLectureSessions({String? courseId}) async {
    var query = client
        .from('lecture_sessions')
        .select('*, courses(*), instructors(*), course_assignments(*), attendance_records(*)');
    
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createLectureSession({
    required String courseId,
    required String instructorId,
    required String scheduleId,
    required DateTime date,
    required DateTime startTime,
  }) async {
    final response = await client
        .from('lecture_sessions')
        .insert({
          'course_id': courseId,
          'instructor_id': instructorId,
          'schedule_id': scheduleId,
          'date': date.toIso8601String(),
          'start_time': startTime.toIso8601String(),
        })
        .select()
        .single();
    return response;
  }

  // Attendance Methods
  static Future<List<Map<String, dynamic>>> getAttendanceRecords({
    String? sessionId,
    String? studentId,
  }) async {
    var query = client
        .from('attendance_records')
        .select('*, students(*), lecture_sessions(*)');
    
    if (sessionId != null) {
      query = query.eq('session_id', sessionId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> markAttendance({
    required String studentId,
    required String sessionId,
    required bool present,
  }) async {
    final response = await client
        .from('attendance_records')
        .insert({
          'student_id': studentId,
          'session_id': sessionId,
          'present': present,
        })
        .select()
        .single();
    return response;
  }

  // QR Scan Methods
  static Future<Map<String, dynamic>> recordQRScan({
    required String studentId,
    required String sessionId,
  }) async {
    final response = await client
        .from('student_qr_scans')
        .insert({
          'student_id': studentId,
          'session_id': sessionId,
          'status': 'tentative',
        })
        .select()
        .single();
    return response;
  }

  static Future<void> finalizeQRScan({
    required String scanId,
  }) async {
    await client
        .from('student_qr_scans')
        .update({'status': 'finalized'})
        .eq('id', scanId);
  }

  // Device Login Methods
  static Future<void> recordDeviceLogin({
    required String studentId,
    required String deviceId,
  }) async {
    await client
        .from('device_logins')
        .upsert({
          'student_id': studentId,
          'device_id': deviceId,
          'last_login': DateTime.now().toIso8601String(),
        });
  }
} 