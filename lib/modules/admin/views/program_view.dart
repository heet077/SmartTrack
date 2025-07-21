import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/program_controller.dart';
import '../models/program_model.dart';

class ProgramView extends StatefulWidget {
  const ProgramView({Key? key}) : super(key: key);

  @override
  State<ProgramView> createState() => _ProgramViewState();
}

class _ProgramViewState extends State<ProgramView> {
  final ProgramController controller = Get.find<ProgramController>();
  late final TextEditingController durationController;
  final RxString selectedProgram = ''.obs;

  // List of DAIICT programs with their short names
  static const Map<String, String> daiictPrograms = {
    'B.Tech (ICT)': 'Bachelor of Technology in Information & Communication Technology',
    'B.Tech (ICT-CS)': 'Bachelor of Technology in ICT with minor in Computer Science',
    'M.Tech (ICT)': 'Master of Technology in Information & Communication Technology',
    'M.Sc (IT)': 'Master of Science in Information Technology',
    'M.Des': 'Master of Design',
    'Ph.D': 'Doctor of Philosophy',
  };

  @override
  void initState() {
    super.initState();
    durationController = TextEditingController();
    selectedProgram.value = daiictPrograms.keys.first;
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Academic Programs',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => controller.checkMscITProgram(),
            tooltip: 'Check MSc IT Program',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search programs...',
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
                        onPressed: controller.loadPrograms,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final programs = controller.filteredPrograms;
              if (programs.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchQuery.value.isEmpty
                        ? 'No programs added yet'
                        : 'No programs found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadPrograms,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return _buildProgramCard(program);
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
      ),
    );
  }

  Widget _buildProgramCard(Program program) {
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
                    program.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      '${program.duration} Semesters',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
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
                    _showAddEditDialog(context, program);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, program.id);
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

  Future<void> _showAddEditDialog(BuildContext context, [Program? program]) async {
    final isEditing = program != null;

    // Reset state
    selectedProgram.value = program?.name ?? daiictPrograms.keys.first;
    durationController.text = program?.duration.toString() ?? '';

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Program' : 'Add New Program',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Program',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Obx(() => DropdownButton<String>(
                          value: selectedProgram.value,
                          isExpanded: true,
                          underline: Container(),
                          items: daiictPrograms.keys.map((String program) {
                            return DropdownMenuItem<String>(
                              value: program,
                              child: Text(
                                program,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              selectedProgram.value = newValue;
                            }
                          },
                        )),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration (in semesters)',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[700],
                          ),
                          hintText: 'Enter program duration',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (durationController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter program duration',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final duration = int.tryParse(durationController.text);
                      if (duration == null || duration <= 0) {
                        Get.snackbar(
                          'Error',
                          'Please enter a valid duration',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final newProgram = Program(
                        id: isEditing ? program!.id : '',
                        name: selectedProgram.value,
                        duration: duration,
                      );

                      if (isEditing) {
                        controller.updateProgram(newProgram);
                      } else {
                        controller.addProgram(newProgram);
                      }

                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Update' : 'Add',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }

  Future<void> _showDeleteDialog(BuildContext context, String id) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Program',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this program?',
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
                controller.deleteProgram(id);
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