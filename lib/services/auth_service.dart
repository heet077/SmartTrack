import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final supabase = Supabase.instance.client;

  // Hash password before storing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String userType,
    required String name,
  }) async {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'user_type': userType,
        'name': name,
      },
    );

    if (res.user != null) {
      // Insert user details into the appropriate table based on user type
      final table = userType.toLowerCase() == 'student' ? 'students' : 'professors';
      await supabase.from(table).insert({
        'id': res.user!.id,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return res;
  }

  Future<Map<String, dynamic>?> signIn({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      print('Login attempt:');
      print('Username: $username');
      print('Password: $password');
      print('User Type: $userType');

      if (userType.toLowerCase() == 'professor') {
        print('Attempting professor login using instructors table...');
        // For professors, query the instructors table directly
        final response = await supabase
            .from('instructors')
            .select()
            .eq('email', username.trim().toLowerCase())
            .eq('password', password.trim())
            .maybeSingle();

        print('Professor lookup response: $response');
        
        if (response != null) {
          print('Professor login successful');
          // Add user_type to the response for consistency
          final enrichedResponse = Map<String, dynamic>.from(response);
          enrichedResponse['user_type'] = 'professor';
          return enrichedResponse;
        }
        print('Professor login failed - Invalid credentials');
        return null;
      } else {
        // Student login logic using email
        print('Attempting student login...');
        final response = await supabase
            .from('students')
            .select()
            .eq('email', username.trim().toLowerCase())
            .eq('password', password.trim())
            .maybeSingle();

        print('Student lookup response: $response');

        if (response != null) {
          print('Student login successful');
          // Add user_type to the response for consistency
          final enrichedResponse = Map<String, dynamic>.from(response);
          enrichedResponse['user_type'] = 'student';
          return enrichedResponse;
        }
        print('Student login failed - Invalid credentials');
        return null;
      }
    } catch (e) {
      print('Login error details: $e');
      if (e.toString().contains('no rows returned')) {
        print('No user found with these credentials');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    Get.offAllNamed('/login');
  }

  Future<String?> getUserType() async {
    try {
      final username = getCurrentUsername();
      if (username == null) return null;
      
      final response = await supabase
          .from('all_logins')
          .select('user_type')
          .eq('username', username)
          .single();
      return response['user_type'];
    } catch (e) {
      return null;
    }
  }

  String? getCurrentUsername() {
    return supabase.auth.currentSession?.user.email;
  }

  Future<Map<String, dynamic>?> getCurrentUserDetails() async {
    try {
      final username = getCurrentUsername();
      if (username == null) return null;

      final response = await supabase
          .from('all_logins')
          .select()
          .eq('username', username)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  bool get isLoggedIn => supabase.auth.currentSession != null;

  // Get current user's name
  String? get currentUserName => supabase.auth.currentSession?.user.userMetadata?['name'];

  Stream<AuthState> get authStateChange => supabase.auth.onAuthStateChange;
} 