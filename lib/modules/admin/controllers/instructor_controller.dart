import 'package:get/get.dart';
import '../models/instructor_model.dart';
import '../../../services/supabase_service.dart';

class InstructorController extends GetxController {
  final RxList<Instructor> instructors = <Instructor>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInstructors();
  }

  List<Instructor> get filteredInstructors {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return instructors;
    return instructors.where((instructor) {
      return instructor.name.toLowerCase().contains(query) ||
          instructor.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadInstructors() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Get all instructors
      final response = await SupabaseService.client
          .from('instructors')
          .select()
          .order('name');
      
      // Get all instructor program assignments
      final programAssignments = await SupabaseService.client
          .from('instructor_programs')
          .select('instructor_id, program_id');

      // Create a map of instructor IDs to their program IDs
      final programMap = <String, List<String>>{};
      for (final assignment in programAssignments as List) {
        final instructorId = assignment['instructor_id'] as String;
        final programId = assignment['program_id'] as String;
        programMap.putIfAbsent(instructorId, () => []).add(programId);
      }

      // Create instructor objects with their program assignments
      final List<Instructor> loadedInstructors = (response as List)
          .map((data) => Instructor.fromMap(
                data,
                programIds: programMap[data['id']] ?? [],
              ))
          .toList();
      
      instructors.value = loadedInstructors;
    } catch (e) {
      error.value = 'Failed to load instructors';
      print('Error loading instructors: $e');
      Get.snackbar(
        'Error',
        'Failed to load instructors: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addInstructor(Instructor instructor) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('Adding instructor with program IDs: ${instructor.programIds}');

      // First, insert the instructor
      final response = await SupabaseService.client
          .from('instructors')
          .insert(instructor.toMap())
          .select()
          .single();

      print('Instructor created with ID: ${response['id']}');

      // Get the new instructor's ID
      final newInstructor = Instructor.fromMap(response, programIds: instructor.programIds);

      // Then, insert the program assignments
      if (instructor.programIds.isNotEmpty) {
        final programAssignments = instructor.programIds.map((programId) => {
          'instructor_id': newInstructor.id,
          'program_id': programId,
        }).toList();

        print('Creating program assignments: $programAssignments');

        await SupabaseService.client
            .from('instructor_programs')
            .insert(programAssignments);
      }

      Get.back();
      Get.snackbar(
        'Success',
        'Instructor added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadInstructors();
    } catch (e) {
      error.value = 'Failed to add instructor';
      print('Error adding instructor: $e');
      Get.snackbar(
        'Error',
        'Failed to add instructor: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateInstructor(Instructor instructor) async {
    try {
      isLoading.value = true;
      error.value = '';

      // First, update the instructor's basic info
      await SupabaseService.client
          .from('instructors')
          .update(instructor.toMap())
          .eq('id', instructor.id);

      // Then, delete all existing program assignments
      await SupabaseService.client
          .from('instructor_programs')
          .delete()
          .eq('instructor_id', instructor.id);

      // Finally, insert the new program assignments
      if (instructor.programIds.isNotEmpty) {
        await SupabaseService.client
            .from('instructor_programs')
            .insert(instructor.createProgramAssignments());
      }

      Get.back();
      Get.snackbar(
        'Success',
        'Instructor updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadInstructors();
    } catch (e) {
      error.value = 'Failed to update instructor';
      print('Error updating instructor: $e');
      Get.snackbar(
        'Error',
        'Failed to update instructor: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteInstructor(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      // First, delete all program assignments
      await SupabaseService.client
          .from('instructor_programs')
          .delete()
          .eq('instructor_id', id);

      // Then, delete the instructor
      await SupabaseService.client
          .from('instructors')
          .delete()
          .eq('id', id);

      Get.back();
      Get.snackbar(
        'Success',
        'Instructor deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      instructors.removeWhere((instructor) => instructor.id == id);
    } catch (e) {
      error.value = 'Failed to delete instructor';
      print('Error deleting instructor: $e');
      Get.snackbar(
        'Error',
        'Failed to delete instructor: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 