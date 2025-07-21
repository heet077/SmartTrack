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
    'BTech ICT': 'Bachelor of Technology in Information & Communication Technology',
    'BTech ICT-CS': 'Bachelor of Technology in ICT with minor in Computer Science',
    'BTech MnC': 'Bachelor of Technology in Mathematics and Computing',
    'BTech EVD': 'Bachelor of Technology in Electronics and VLSI Design',
    'MTech ICT-SS': 'Master of Technology in ICT with specialization in Signal and Systems',
    'MTech ICT-ML': 'Master of Technology in ICT with specialization in Machine Learning',
    'MTech ICT-VLSI&ES': 'Master of Technology in ICT with specialization in VLSI & Embedded Systems',
    'MTech ICT-WCSP': 'Master of Technology in ICT with specialization in Wireless Communication & Signal Processing',
    'MTech EC': 'Master of Technology in Electronics and Communication',
    'MSc IT': 'Master of Science in Information Technology',
    'MSc DS': 'Master of Science in Data Science',
    'MSc AA': 'Master of Science in Advanced Analytics',
    'PhD': 'Doctor of Philosophy',
  };

  @override
  void initState() {
    super.initState();
    durationController = TextEditingController();
    
    // Set initial value only if editing, otherwise use first program
    if (Get.arguments != null && Get.arguments['program'] != null) {
      final Program program = Get.arguments['program'];
      // Find the matching program name in our map
      final matchingProgram = daiictPrograms.keys.firstWhere(
        (key) => key == program.name,
        orElse: () => daiictPrograms.keys.first,
      );
      selectedProgram.value = matchingProgram;
      durationController.text = program.duration.toString();
    } else {
      selectedProgram.value = daiictPrograms.keys.first;
    }
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
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(),
                          ),
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
                      '${program.totalSemesters} Semesters',
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
                    _showAddEditDialog(context, program: program);
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

  void _showAddEditDialog(BuildContext context, {Program? program}) {
    final bool isEditing = program != null;
    
    if (isEditing) {
      // Find the matching program name in our map
      final matchingProgram = daiictPrograms.keys.firstWhere(
        (key) => key == program.name,
        orElse: () => daiictPrograms.keys.first,
      );
      selectedProgram.value = matchingProgram;
      durationController.text = program.duration.toString();
    } else {
      selectedProgram.value = daiictPrograms.keys.first;
      durationController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isEditing ? 'Edit Program' : 'Add New Program',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => DropdownButton<String>(
                    value: selectedProgram.value,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    items: daiictPrograms.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: SizedBox(
                          height: 48,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                    labelText: 'Duration (semesters)',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Enter program duration',
                    hintStyle: GoogleFonts.poppins(),
                  ),
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
                final duration = int.tryParse(durationController.text.trim());

                if (duration == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid duration'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // Calculate total semesters (2 per year)
                final totalSemesters = duration * 2;

                // Generate a code based on the program name
                final code = selectedProgram.value.replaceAll(' ', '_').toUpperCase();

                // Determine program type from the name
                String programType = 'BTech';
                final name = selectedProgram.value.toLowerCase();
                if (name.contains('mtech') || name.contains('m.tech')) {
                  programType = 'MTech';
                } else if (name.contains('msc') || name.contains('m.sc')) {
                  programType = 'MSc';
                } else if (name.contains('phd') || name.contains('ph.d')) {
                  programType = 'PhD';
                }

                if (isEditing) {
                  final updatedProgram = Program(
                    id: program!.id,
                    name: selectedProgram.value,
                    code: code,
                    duration: duration,
                    totalSemesters: totalSemesters,
                    programType: programType,
                  );
                  controller.updateProgram(updatedProgram);
                } else {
                  controller.addProgram(
                    selectedProgram.value,
                    code,
                    duration,
                    totalSemesters,
                    programType,
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