import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../controllers/program_controller.dart';
import '../models/course_model.dart';

class CourseView extends StatefulWidget {
  const CourseView({Key? key}) : super(key: key);

  @override
  _CourseViewState createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  final CourseController controller = Get.find<CourseController>();
  late final TextEditingController nameController;
  late final TextEditingController codeController;
  late final TextEditingController creditsController;
  late final TextEditingController semesterController;
  late final TextEditingController theoryHoursController;
  late final TextEditingController tutorialHoursController;
  late final TextEditingController labHoursController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    codeController = TextEditingController();
    creditsController = TextEditingController();
    semesterController = TextEditingController();
    theoryHoursController = TextEditingController(text: '0');
    tutorialHoursController = TextEditingController(text: '0');
    labHoursController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    creditsController.dispose();
    semesterController.dispose();
    theoryHoursController.dispose();
    tutorialHoursController.dispose();
    labHoursController.dispose();
    super.dispose();
  }

  void _clearForm() {
    nameController.clear();
    codeController.clear();
    creditsController.clear();
    semesterController.clear();
    theoryHoursController.text = '0';
    tutorialHoursController.text = '0';
    labHoursController.text = '0';
    controller.selectedCourseType.value = 'core';  // Reset course type
  }

  void _populateForm(Course course) {
    nameController.text = course.name;
    codeController.text = course.code;
    creditsController.text = course.credits.toString();
    semesterController.text = course.semester.toString();
    theoryHoursController.text = (course.theoryHours ?? 0).toString();
    tutorialHoursController.text = (course.tutorialHours ?? 0).toString();
    labHoursController.text = (course.labHours ?? 0).toString();
    controller.selectedCourseType.value = course.courseType ?? 'core';  // Handle nullable courseType
  }

  void _showAddDialog(BuildContext context) {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Course',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: _buildCourseForm(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validateForm()) {
                final course = Course(
                  id: '',
                  name: nameController.text,
                  code: codeController.text,
                  credits: int.parse(creditsController.text),
                  programId: controller.selectedProgramId.value,
                  semester: int.parse(semesterController.text),
                  theoryHours: int.parse(theoryHoursController.text),
                  tutorialHours: int.parse(tutorialHoursController.text),
                  labHours: int.parse(labHoursController.text),
                  courseType: controller.selectedCourseType.value,
                );
                controller.addCourse(course);
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Course course) {
    _populateForm(course);
    controller.selectedProgramId.value = course.programId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Course',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: _buildCourseForm(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validateForm()) {
                final updatedCourse = Course(
                  id: course.id,
                  name: nameController.text,
                  code: codeController.text,
                  credits: int.parse(creditsController.text),
                  programId: controller.selectedProgramId.value,
                  semester: int.parse(semesterController.text),
                  theoryHours: int.parse(theoryHoursController.text),
                  tutorialHours: int.parse(tutorialHoursController.text),
                  labHours: int.parse(labHoursController.text),
                  courseType: controller.selectedCourseType.value,
                );
                controller.updateCourse(updatedCourse);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Course',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${course.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => controller.deleteCourse(course.id),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseForm() {
    final programController = Get.find<ProgramController>();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Course Name',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: codeController,
          decoration: InputDecoration(
            labelText: 'Course Code',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: creditsController,
          decoration: InputDecoration(
            labelText: 'Credits',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: semesterController,
          decoration: InputDecoration(
            labelText: 'Semester',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        Text(
          'Course Hours',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: theoryHoursController,
                decoration: InputDecoration(
                  labelText: 'Theory',
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: tutorialHoursController,
                decoration: InputDecoration(
                  labelText: 'Tutorial',
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: labHoursController,
                decoration: InputDecoration(
                  labelText: 'Lab',
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: controller.selectedCourseType.value,
          decoration: InputDecoration(
            labelText: 'Course Type',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
          items: Course.courseTypes.asMap().entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(
                Course.courseTypeDisplays[entry.key],
                style: GoogleFonts.poppins(),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedCourseType.value = value;
            }
          },
        ),
      ],
    );
  }

  bool _validateForm() {
    if (nameController.text.isEmpty ||
        codeController.text.isEmpty ||
        creditsController.text.isEmpty ||
        semesterController.text.isEmpty ||
        controller.selectedProgramId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => controller.checkMscITCourses(),
            tooltip: 'Check MSc IT Courses',
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade200,
                      width: 2,
                    ),
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
                      return _buildCourseCard(course, Get.find<ProgramController>());
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Course',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, ProgramController programController) {
    final program = programController.programs
        .firstWhereOrNull((p) => p.id == course.programId);
    final programName = program?.name ?? 'Unknown Program';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.hoursFormat,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Program: $programName',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${course.courseTypeDisplay}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context, course);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, course);
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

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog([Course? course]) async {
    final programController = Get.find<ProgramController>();
    
    if (course != null) {
      _populateForm(course);
      controller.selectedProgramId.value = course.programId;
    } else {
      _clearForm();
      controller.selectedProgramId.value = programController.programs.first.id;
    }

    await Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course == null ? 'Add Course' : 'Edit Course',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: creditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Credits',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: semesterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: controller.selectedProgramId.value,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
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
                      controller.selectedProgramId.value = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: controller.selectedCourseType.value,
                  decoration: const InputDecoration(
                    labelText: 'Course Type',
                    border: OutlineInputBorder(),
                  ),
                  items: Course.courseTypes.asMap().entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.value,
                      child: Text(
                        Course.courseTypeDisplays[entry.key],
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedCourseType.value = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a course type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Course Hours',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: theoryHoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Theory',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tutorialHoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tutorial',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: labHoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lab',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final code = codeController.text.trim();
                        final credits = int.tryParse(creditsController.text) ?? 0;
                        final semester = int.tryParse(semesterController.text) ?? 1;
                        final theoryHours = int.tryParse(theoryHoursController.text) ?? 0;
                        final tutorialHours = int.tryParse(tutorialHoursController.text) ?? 0;
                        final labHours = int.tryParse(labHoursController.text) ?? 0;

                        if (name.isEmpty || code.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please fill all required fields',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        final newCourse = Course(
                          id: course?.id ?? '',
                          name: name,
                          code: code,
                          credits: credits,
                          programId: controller.selectedProgramId.value,
                          semester: semester,
                          theoryHours: theoryHours,
                          tutorialHours: tutorialHours,
                          labHours: labHours,
                          courseType: controller.selectedCourseType.value,
                        );

                        if (course == null) {
                          controller.addCourse(newCourse);
                        } else {
                          controller.updateCourse(newCourse);
                        }
                      },
                      child: Text(
                        course == null ? 'Add' : 'Update',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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