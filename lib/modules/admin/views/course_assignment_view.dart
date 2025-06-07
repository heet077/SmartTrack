import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_assignment_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/instructor_controller.dart';
import '../models/course_assignment_model.dart';

class CourseAssignmentView extends StatefulWidget {
  const CourseAssignmentView({Key? key}) : super(key: key);

  @override
  State<CourseAssignmentView> createState() => _CourseAssignmentViewState();
}

class _CourseAssignmentViewState extends State<CourseAssignmentView> {
  final CourseAssignmentController controller = Get.find<CourseAssignmentController>();
  final CourseController courseController = Get.find<CourseController>();
  final InstructorController instructorController = Get.find<InstructorController>();
  
  late final TextEditingController classroomController;
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;
  String selectedInstructorId = '';
  String selectedCourseId = '';
  int selectedDayOfWeek = 1;

  @override
  void initState() {
    super.initState();
    classroomController = TextEditingController();
    startTimeController = TextEditingController();
    endTimeController = TextEditingController();
    
    // Load required data if not already loaded
    if (courseController.courses.isEmpty) {
      courseController.loadCourses();
    }
    if (instructorController.instructors.isEmpty) {
      instructorController.loadInstructors();
    }
  }

  @override
  void dispose() {
    classroomController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Assignments',
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
                hintText: 'Search assignments...',
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
                        onPressed: controller.loadAssignments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final assignments = controller.filteredAssignments;
              if (assignments.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchQuery.value.isEmpty
                        ? 'No assignments added yet'
                        : 'No assignments found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadAssignments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return _buildAssignmentCard(assignment);
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

  Widget _buildAssignmentCard(CourseAssignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.courseName ?? 'Unknown Course',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Course Code: ${assignment.courseCode ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instructor: ${assignment.instructorName ?? 'Unknown'}',
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
                        _showAddEditDialog(context, assignment);
                        break;
                      case 'delete':
                        _showDeleteDialog(context, assignment);
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
            const SizedBox(height: 8),
            Text(
              'Classroom: ${assignment.classroom}',
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
                    assignment.dayName,
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
                    '${assignment.startTime} - ${assignment.endTime}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, [CourseAssignment? assignment]) async {
    final isEditing = assignment != null;
    
    // Set initial values if editing
    if (isEditing) {
      selectedInstructorId = assignment.instructorId;
      selectedCourseId = assignment.courseId;
      selectedDayOfWeek = assignment.dayOfWeek;
      classroomController.text = assignment.classroom;
      startTimeController.text = assignment.startTime;
      endTimeController.text = assignment.endTime;
    } else {
      selectedInstructorId = instructorController.instructors.first.id;
      selectedCourseId = courseController.courses.first.id;
      selectedDayOfWeek = 1;
      classroomController.clear();
      startTimeController.clear();
      endTimeController.clear();
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Assignment' : 'Add New Assignment',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedInstructorId,
                    decoration: InputDecoration(
                      labelText: 'Instructor',
                      labelStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                    ),
                    items: instructorController.instructors.map((instructor) {
                      return DropdownMenuItem<String>(
                        value: instructor.id,
                        child: Text(
                          instructor.name,
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedInstructorId = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    decoration: InputDecoration(
                      labelText: 'Course',
                      labelStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                    ),
                    items: courseController.courses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course.id,
                        child: Text(
                          '${course.code} - ${course.name}',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedCourseId = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: classroomController,
                    decoration: InputDecoration(
                      labelText: 'Classroom',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter classroom number/name',
                      hintStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDayOfWeek,
                    decoration: InputDecoration(
                      labelText: 'Day of Week',
                      labelStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(7, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(
                          CourseAssignment.daysOfWeek[index],
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        selectedDayOfWeek = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            labelStyle: GoogleFonts.poppins(),
                            hintText: 'HH:MM',
                            hintStyle: GoogleFonts.poppins(),
                            border: const OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              startTimeController.text = 
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            }
                          },
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: endTimeController,
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            labelStyle: GoogleFonts.poppins(),
                            hintText: 'HH:MM',
                            hintStyle: GoogleFonts.poppins(),
                            border: const OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              endTimeController.text = 
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            }
                          },
                          readOnly: true,
                        ),
                      ),
                    ],
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
                  final classroom = classroomController.text.trim();
                  final startTime = startTimeController.text.trim();
                  final endTime = endTimeController.text.trim();

                  if (selectedInstructorId.isEmpty || selectedCourseId.isEmpty || 
                      classroom.isEmpty || startTime.isEmpty || endTime.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final newAssignment = CourseAssignment(
                    id: assignment?.id ?? '',
                    instructorId: selectedInstructorId,
                    courseId: selectedCourseId,
                    classroom: classroom,
                    dayOfWeek: selectedDayOfWeek,
                    startTime: startTime,
                    endTime: endTime,
                  );

                  if (isEditing) {
                    controller.updateAssignment(newAssignment);
                  } else {
                    controller.addAssignment(newAssignment);
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
        classroomController.clear();
        startTimeController.clear();
        endTimeController.clear();
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, CourseAssignment assignment) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Assignment',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this course assignment?',
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
                controller.deleteAssignment(assignment.id);
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