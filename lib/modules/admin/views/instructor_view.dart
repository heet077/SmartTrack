import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/instructor_controller.dart';
import '../controllers/program_controller.dart';
import '../models/instructor_model.dart';
import '../models/program_model.dart';

class InstructorView extends StatefulWidget {
  const InstructorView({Key? key}) : super(key: key);

  @override
  State<InstructorView> createState() => _InstructorViewState();
}

class _InstructorViewState extends State<InstructorView> {
  final InstructorController controller = Get.find<InstructorController>();
  final ProgramController programController = Get.find<ProgramController>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  final RxList<String> selectedProgramIds = <String>[].obs;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Instructors',
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
                hintText: 'Search instructors...',
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
                        onPressed: controller.loadInstructors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final instructors = controller.filteredInstructors;
              if (instructors.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchQuery.value.isEmpty
                        ? 'No instructors added yet'
                        : 'No instructors found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadInstructors,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: instructors.length,
                  itemBuilder: (context, index) {
                    final instructor = instructors[index];
                    return _buildInstructorCard(instructor);
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

  Widget _buildInstructorCard(Instructor instructor) {
    final assignedPrograms = programController.programs
        .where((program) => instructor.programIds.contains(program.id))
        .toList();

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
                    instructor.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor.email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (instructor.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      instructor.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (assignedPrograms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignedPrograms.map((program) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            program.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
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
                    _showAddEditDialog(context, instructor);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, instructor);
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

  Future<void> _showAddEditDialog(BuildContext context, [Instructor? instructor]) async {
    final isEditing = instructor != null;
    
    // Set initial values if editing
    if (isEditing) {
      nameController.text = instructor.name;
      emailController.text = instructor.email;
      phoneController.text = instructor.phone ?? '';
      selectedProgramIds.value = List.from(instructor.programIds);
    } else {
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      selectedProgramIds.clear();
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Instructor' : 'Add New Instructor',
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
                      hintText: 'Enter instructor name',
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
                      hintText: 'Enter instructor email',
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
                  const SizedBox(height: 24),
                  Text(
                    'Assigned Programs',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (programController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (programController.programs.isEmpty) {
                      return Text(
                        'No programs available',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      );
                    }

                    return Column(
                      children: programController.programs.map((program) {
                        return CheckboxListTile(
                          title: Text(
                            program.name,
                            style: GoogleFonts.poppins(),
                          ),
                          value: selectedProgramIds.contains(program.id),
                          onChanged: (bool? value) {
                            if (value == true) {
                              selectedProgramIds.add(program.id);
                            } else {
                              selectedProgramIds.remove(program.id);
                            }
                          },
                        );
                      }).toList(),
                    );
                  }),
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

                  if (name.isEmpty || email.isEmpty || selectedProgramIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields and select at least one program'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (isEditing) {
                    final updatedInstructor = Instructor(
                      id: instructor!.id,
                    name: name,
                    email: email,
                    phone: phone.isNotEmpty ? phone : null,
                    programIds: selectedProgramIds.toList(),
                      username: instructor!.username,  // Keep existing username
                      password: instructor!.password,  // Keep existing password
                  );
                    controller.updateInstructor(updatedInstructor);
                  } else {
                    // For new instructors, use email as both username and password
                    controller.addInstructor(
                      name,
                      email,
                      phone.isNotEmpty ? phone : null,
                      selectedProgramIds.toList(),
                    );
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
        selectedProgramIds.clear();
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, Instructor instructor) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Instructor',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${instructor.name}?',
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
                controller.deleteInstructor(instructor.id);
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