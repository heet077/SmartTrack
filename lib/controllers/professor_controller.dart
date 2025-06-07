import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professor.dart';

class ProfessorController extends GetxController {
  final supabase = Supabase.instance.client;
  final Rx<Professor?> currentProfessor = Rx<Professor?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfessorData();
  }

  Future<void> loadProfessorData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get the current professor's email from the session
      final email = supabase.auth.currentSession?.user.email;
      if (email == null) {
        error.value = 'No authenticated professor found';
        return;
      }

      // Fetch professor data with their assigned courses and schedules
      final response = await supabase
          .from('instructors')
          .select('''
            *,
            course_assignments!inner (
              classroom,
              day_of_week,
              start_time,
              end_time,
              course:courses!inner (
                id,
                name,
                code,
                semester
              )
            )
          ''')
          .eq('email', email)
          .single();

      if (response != null) {
        // Transform the response to match our Professor model
        final assignments = (response['course_assignments'] as List?)
            ?.map((assignment) => CourseAssignment.fromJson({
                  ...assignment,
                  'course': assignment['course'],
                }))
            .toList() ?? [];

        currentProfessor.value = Professor(
          id: response['id'] ?? '',
          name: response['name'] ?? '',
          email: response['email'] ?? '',
          assignedCourses: assignments,
        );
      }
    } catch (e) {
      error.value = 'Error loading professor data: $e';
      print('Error loading professor data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadProfessorData();
  }
} 