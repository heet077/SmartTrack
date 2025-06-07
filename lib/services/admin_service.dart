import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .order('username');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProfessors() async {
    try {
      final response = await _supabase
          .from('instructors')
          .select()
          .order('username');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching professors: $e');
      return [];
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String userType,
    required String name,
    required String rollNo,
  }) async {
    try {
      if (userType == 'Student') {
        await _supabase.from('students').insert({
          'username': email,
          'password': password,
          'name': name,
          'roll_no': rollNo,
        });
      } else if (userType == 'Professor') {
        await _supabase.from('instructors').insert({
          'username': email,
          'password': password,
          'name': name,
        });
      }
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      // First try to find the user in students table
      final studentResponse = await _supabase
          .from('students')
          .select()
          .eq('id', userId)
          .single();

      if (studentResponse != null) {
        await _supabase
            .from('students')
            .update({'password': newPassword})
            .eq('id', userId);
        return true;
      }

      // If not found in students, try professors
      final professorResponse = await _supabase
          .from('instructors')
          .select()
          .eq('id', userId)
          .single();

      if (professorResponse != null) {
        await _supabase
            .from('instructors')
            .update({'password': newPassword})
            .eq('id', userId);
        return true;
      }

      return false;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // Try to delete from students first
      final studentResponse = await _supabase
          .from('students')
          .delete()
          .eq('id', userId);

      if (studentResponse != null) {
        return true;
      }

      // If not found in students, try professors
      final professorResponse = await _supabase
          .from('instructors')
          .delete()
          .eq('id', userId);

      if (professorResponse != null) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
} 