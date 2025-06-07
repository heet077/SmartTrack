import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_controller.dart';
import '../controllers/program_controller.dart';
import '../models/student_model.dart';
import '../models/program_model.dart';

class StudentView extends StatefulWidget {
  const StudentView({Key? key}) : super(key: key);

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  final StudentController controller = Get.find<StudentController>();
  final ProgramController programController = Get.find<ProgramController>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController enrollmentNoController;
  late final TextEditingController semesterController;
  String selectedProgramId = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    enrollmentNoController = TextEditingController();
    semesterController = TextEditingController();
    // Load programs if not already loaded
    if (programController.programs.isEmpty) {
      programController.loadPrograms();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    enrollmentNoController.dispose();
    semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Students',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search students...',
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
                        onPressed: controller.loadStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final students = controller.filteredStudents;
              if (students.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchQuery.value.isEmpty
                        ? 'No students added yet'
                        : 'No students found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadStudents,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(student);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final program = programController.programs
        .firstWhereOrNull((p) => p.id == student.programId);

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
                    student.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (student.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      student.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                          student.enrollmentNo,
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
                          'Semester ${student.semester}',
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
                    _showAddEditDialog(context, student);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, student);
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

  Future<void> _showAddEditDialog(BuildContext context, [Student? student]) async {
    final isEditing = student != null;
    
    // Set initial values if editing
    if (isEditing) {
      nameController.text = student.name;
      emailController.text = student.email;
      phoneController.text = student.phone ?? '';
      enrollmentNoController.text = student.enrollmentNo;
      semesterController.text = student.semester.toString();
      selectedProgramId = student.programId;
    } else {
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      enrollmentNoController.clear();
      semesterController.clear();
      selectedProgramId = programController.programs.first.id;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Student' : 'Add New Student',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter student name',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter student email',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone (optional)',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter phone number',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: enrollmentNoController,
                    decoration: InputDecoration(
                      labelText: 'Enrollment No',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter enrollment number',
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
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(),
                ),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final phone = phoneController.text.trim();
                  final enrollmentNo = enrollmentNoController.text.trim();
                  final semesterText = semesterController.text.trim();
                  final semester = int.tryParse(semesterText);

                  if (name.isEmpty || email.isEmpty || enrollmentNo.isEmpty || 
                      semester == null || selectedProgramId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final newStudent = Student(
                    id: student?.id ?? '',
                    name: name,
                    email: email,
                    phone: phone.isNotEmpty ? phone : null,
                    enrollmentNo: enrollmentNo,
                    programId: selectedProgramId,
                    semester: semester,
                  );

                  if (isEditing) {
                    controller.updateStudent(newStudent);
                  } else {
                    controller.addStudent(newStudent);
                  }

                  Navigator.of(context).pop();
                },
                child: Text(
                  isEditing ? 'Update' : 'Add',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      // Clear controllers if dialog is dismissed
      if (!isEditing) {
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        enrollmentNoController.clear();
        semesterController.clear();
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, Student student) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Student',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${student.name}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.deleteStudent(student.id);
                Navigator.of(context).pop();
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
        );
      },
    );
  }
} 