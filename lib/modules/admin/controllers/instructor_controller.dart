import 'package:get/get.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
      
      // Get all instructor program mappings
      final programMappings = await SupabaseService.client
          .from('instructor_program_mappings')
          .select('instructor_id, program_id');

      // Create a map of instructor IDs to their program IDs
      final programMap = <String, List<String>>{};
      for (final mapping in programMappings as List) {
        final instructorId = mapping['instructor_id'] as String;
        final programId = mapping['program_id'] as String;
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
        'Failed to load instructors',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addInstructor(String name, String email, String? phone, List<String> programIds) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Create new instructor with email as both username and initial password
      final newInstructor = Instructor(
        id: '',
        name: name,
        email: email,
        phone: phone,
        programIds: programIds,
        username: email,  // Use email as username
        password: email,  // Use email as initial password
      );

      // Insert instructor into database
      final response = await SupabaseService.client
          .from('instructors')
          .insert(newInstructor.toMap())
          .select()
          .single();

      final createdInstructor = Instructor.fromMap(response, programIds: programIds);

      // Insert program mappings
      if (programIds.isNotEmpty) {
        final mappings = programIds.map((programId) => {
          'instructor_id': createdInstructor.id,
          'program_id': programId,
        }).toList();

        await SupabaseService.client
            .from('instructor_program_mappings')
            .insert(mappings);
      }

      // Add the new instructor to the list
      instructors.add(createdInstructor);

        Get.back();
      Get.snackbar(
        'Success',
        'Instructor added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> updateInstructor(Instructor instructor) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Update instructor basic info
      await SupabaseService.client
          .from('instructors')
          .update(instructor.toMap())
          .eq('id', instructor.id);

      // Get current program mappings
      final currentMappings = await SupabaseService.client
          .from('instructor_program_mappings')
          .select('program_id')
          .eq('instructor_id', instructor.id);

      final currentProgramIds = (currentMappings as List)
          .map((m) => m['program_id'] as String)
          .toList();

      // Find programs to add and remove
      final programsToAdd = instructor.programIds
          .where((id) => !currentProgramIds.contains(id))
          .toList();
      final programsToRemove = currentProgramIds
          .where((id) => !instructor.programIds.contains(id))
          .toList();

      // Add new program mappings
      if (programsToAdd.isNotEmpty) {
        final newMappings = programsToAdd.map((programId) => {
          'instructor_id': instructor.id,
          'program_id': programId,
        }).toList();

        await SupabaseService.client
            .from('instructor_program_mappings')
            .insert(newMappings);
      }

      // Remove old program mappings one by one since Supabase doesn't support IN clause
      for (final programId in programsToRemove) {
        await SupabaseService.client
            .from('instructor_program_mappings')
            .delete()
            .eq('instructor_id', instructor.id)
            .eq('program_id', programId);
      }

      // Update the instructor in the list
      final index = instructors.indexWhere((i) => i.id == instructor.id);
      if (index != -1) {
        instructors[index] = instructor;
      }

      // Show success message
      Get.snackbar(
        'Success',
        'Instructor updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
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

      // Delete program mappings first (cascade delete will handle this, but being explicit)
      await SupabaseService.client
          .from('instructor_program_mappings')
          .delete()
          .eq('instructor_id', id);

      // Then delete the instructor
      await SupabaseService.client
          .from('instructors')
          .delete()
          .eq('id', id);

      // Remove the instructor from the list
      instructors.removeWhere((instructor) => instructor.id == id);

      Get.snackbar(
        'Success',
        'Instructor deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
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