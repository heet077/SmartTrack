import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../controllers/program_controller.dart';
import '../models/course_model.dart';

class CourseView extends StatefulWidget {
  const CourseView({Key? key}) : super(key: key);

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  final CourseController controller = Get.find<CourseController>();
  late final TextEditingController nameController;
  late final TextEditingController codeController;
  late final TextEditingController creditsController;
  late final TextEditingController semesterController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    codeController = TextEditingController();
    creditsController = TextEditingController();
    semesterController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    creditsController.dispose();
    semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programController = Get.find<ProgramController>();
    
    // Load programs if not already loaded
    if (programController.programs.isEmpty) {
      programController.loadPrograms();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Management',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        // Wait for programs to load before showing the course management UI
        if (programController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (programController.programs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Please add programs first',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/admin/dashboard/programs'),
                  child: Text(
                    'Go to Programs',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.error.value,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: controller.loadCourses,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final courses = controller.filteredCourses;
                if (courses.isEmpty) {
                  return Center(
                    child: Text(
                      controller.searchQuery.value.isEmpty
                          ? 'No courses added yet'
                          : 'No courses found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadCourses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _buildCourseCard(course, programController);
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseCard(Course course, ProgramController programController) {
    final program = programController.programs
        .firstWhereOrNull((p) => p.id == course.programId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${course.code}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${course.credits} Credits',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Semester ${course.semester}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (program != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Program: ${program.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showAddEditDialog(context, course);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, course.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, [Course? course]) async {
    final isEditing = course != null;
    final programController = Get.find<ProgramController>();
    
    // Set the values
    nameController.text = course?.name ?? '';
    codeController.text = course?.code ?? '';
    creditsController.text = course?.credits?.toString() ?? '';
    semesterController.text = course?.semester?.toString() ?? '';
    
    String selectedProgramId = course?.programId ?? programController.programs.first.id;

    await Get.dialog(
      AlertDialog(
        title: Text(
          isEditing ? 'Edit Course' : 'Add New Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'Enter course name',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Course Code',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'Enter course code',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Credits',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'Enter course credits',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: semesterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'Enter semester number',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProgramId,
                decoration: InputDecoration(
                  labelText: 'Program',
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
                items: programController.programs.map((program) {
                  return DropdownMenuItem<String>(
                    value: program.id,
                    child: Text(
                      program.name,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedProgramId = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final credits = int.tryParse(creditsController.text.trim());
              final semester = int.tryParse(semesterController.text.trim());

              if (name.isEmpty || code.isEmpty || credits == null || semester == null) {
                Get.snackbar(
                  'Error',
                  'Please fill in all fields correctly',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final newCourse = Course(
                id: course?.id ?? '',  // ID will be generated by the database
                code: code,
                name: name,
                credits: credits,
                programId: selectedProgramId,
                semester: semester,
              );

              if (isEditing) {
                controller.updateCourse(newCourse);
              } else {
                controller.addCourse(newCourse);
              }

              // Clear the controllers
              nameController.clear();
              codeController.clear();
              creditsController.clear();
              semesterController.clear();
              
              Get.back();
            },
            child: Text(
              isEditing ? 'Update' : 'Add',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String id) async {
    await Get.dialog(
      AlertDialog(
        title: Text(
          'Delete Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this course?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.deleteCourse(id);
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
} 