import 'package:get/get.dart';
import '../models/program_model.dart';
import '../../../services/supabase_service.dart';

class ProgramController extends GetxController {
  final RxList<Program> programs = <Program>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPrograms();
    _updateProgramTypes(); // Add this line to update program types
  }

  List<Program> get filteredPrograms {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return programs;
    return programs.where((program) =>
      program.name.toLowerCase().contains(query) ||
      program.code.toLowerCase().contains(query)
    ).toList();
  }

  Future<void> _updateProgramTypes() async {
    try {
      // First check if program_type column exists
      final response = await SupabaseService.client
          .rpc('check_column_exists', params: {
            'table_name': 'programs',
            'column_name': 'program_type'
          });

      if (response == false) {
        // Add program_type column if it doesn't exist
        await SupabaseService.client.rpc('add_program_type_column');
      }

      // Update program types based on program names
      final programs = await SupabaseService.client
          .from('programs')
          .select()
          .filter('program_type', 'is', null);

      for (final program in programs) {
        String type = 'BTech';
        final name = program['name'].toString().toLowerCase();
        
        if (name.contains('mtech') || name.contains('m.tech')) {
          type = 'MTech';
        } else if (name.contains('msc') || name.contains('m.sc')) {
          type = 'MSc';
        } else if (name.contains('phd') || name.contains('ph.d')) {
          type = 'PhD';
        }

        await SupabaseService.client
            .from('programs')
            .update({'program_type': type})
            .eq('id', program['id']);
      }
    } catch (e) {
      print('Error updating program types: $e');
    }
  }

  Future<void> loadPrograms() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('programs')
          .select()
          .order('name');
      
      final List<Program> loadedPrograms = (response as List)
          .map((data) => Program.fromMap(data))
          .toList();
      
      programs.value = loadedPrograms;
    } catch (e) {
      error.value = 'Failed to load programs';
      print('Error loading programs: $e');
      Get.snackbar(
        'Error',
        'Failed to load programs',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProgram(String name, String code, int duration, int totalSemesters, String programType) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client.from('programs').insert({
        'name': name,
        'code': code,
        'duration': duration,
        'total_semesters': totalSemesters,
        'program_type': programType,
      });

      Get.back(); // Close the add dialog
      Get.snackbar(
        'Success',
        'Program added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Reload programs to get the new list with server-generated IDs
      await loadPrograms();
    } catch (e) {
      error.value = 'Failed to add program';
      print('Error adding program: $e');
      Get.snackbar(
        'Error',
        'Failed to add program',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProgram(Program program) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('programs')
          .update({
            'name': program.name,
            'code': program.code,
            'duration': program.duration,
            'total_semesters': program.totalSemesters,
            'program_type': program.programType,
          })
          .eq('id', program.id);

      Get.back(); // Close the edit dialog
      Get.snackbar(
        'Success',
        'Program updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadPrograms(); // Reload to get updated data
    } catch (e) {
      error.value = 'Failed to update program';
      print('Error updating program: $e');
      Get.snackbar(
        'Error',
        'Failed to update program',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProgram(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('programs')
          .delete()
          .eq('id', id);

      Get.back(); // Close the confirmation dialog
      Get.snackbar(
        'Success',
        'Program deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Remove from local list
      programs.removeWhere((program) => program.id == id);
    } catch (e) {
      error.value = 'Failed to delete program';
      print('Error deleting program: $e');
      Get.snackbar(
        'Error',
        'Failed to delete program',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkMscITProgram() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('programs')
          .select()
          .eq('name', 'M.Sc (IT)');

      print('MSc IT Program:');
      for (var program in response) {
        print('Name: ${program['name']}');
        print('Code: ${program['code']}');
        print('Duration: ${program['duration']}');
        print('ID: ${program['id']}');
        print('---');
      }
    } catch (e) {
      print('Error checking MSc IT program: $e');
    } finally {
      isLoading.value = false;
    }
  }
} 