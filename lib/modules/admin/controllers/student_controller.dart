import 'package:get/get.dart';
import '../models/student_model.dart';
import '../../../services/supabase_service.dart';

class StudentController extends GetxController {
  final RxList<Student> students = <Student>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  List<Student> get filteredStudents {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return students;
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.enrollmentNo.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadStudents() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await SupabaseService.client
          .from('students')
          .select('*, programs(*)')
          .order('name');

      final List<Student> loadedStudents = (response as List)
          .map((data) => Student.fromMap(data))
          .toList();
      
      students.value = loadedStudents;
    } catch (e) {
      error.value = 'Failed to load students';
      print('Error loading students: $e');
      Get.snackbar(
        'Error',
        'Failed to load students: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addStudent(Student student) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('Adding student: ${student.toMap()}');

      await SupabaseService.client
          .from('students')
          .insert(student.toMap());

      Get.back();
      Get.snackbar(
        'Success',
        'Student added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadStudents();
    } catch (e) {
      error.value = 'Failed to add student';
      print('Error adding student: $e');
      Get.snackbar(
        'Error',
        'Failed to add student: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('Updating student: ${student.toMap()}');

      await SupabaseService.client
          .from('students')
          .update(student.toMap())
          .eq('id', student.id);

      Get.back();
      Get.snackbar(
        'Success',
        'Student updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadStudents();
    } catch (e) {
      error.value = 'Failed to update student';
      print('Error updating student: $e');
      Get.snackbar(
        'Error',
        'Failed to update student: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await SupabaseService.client
          .from('students')
          .delete()
          .eq('id', id);

      Get.back();
      Get.snackbar(
        'Success',
        'Student deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      students.removeWhere((student) => student.id == id);
    } catch (e) {
      error.value = 'Failed to delete student';
      print('Error deleting student: $e');
      Get.snackbar(
        'Error',
        'Failed to delete student: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 