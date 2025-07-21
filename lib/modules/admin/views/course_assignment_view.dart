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
  String selectedClassroom = '';
  int selectedDayOfWeek = 1;
  final scheduleSlots = <ScheduleSlot>[].obs;

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
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
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
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Schedule Slots:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...assignment.scheduleSlots.map((slot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
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
                      slot.dayName,
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
                      '${slot.startTime} - ${slot.endTime}',
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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slot.classroom,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, [CourseAssignment? assignment]) async {
    final isEditing = assignment != null;
    
    // Check if instructors are loaded
    if (instructorController.instructors.isEmpty) {
      await instructorController.loadInstructors();
      // If still empty after loading, show error
      if (instructorController.instructors.isEmpty) {
        Get.snackbar(
          'Error',
          'No instructors available. Please add instructors first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }
    
    // Set initial values if editing
    if (isEditing) {
      selectedInstructorId = assignment.instructorId;
      selectedCourseId = assignment.courseId;
      scheduleSlots.value = List.from(assignment.scheduleSlots);
    } else {
      selectedInstructorId = instructorController.instructors.first.id;
      selectedCourseId = '';
      scheduleSlots.clear();
    }

    // Track available courses for the selected instructor
    final RxList<Map<String, dynamic>> availableCourses = <Map<String, dynamic>>[].obs;

    // Load initial courses for the selected instructor
    if (selectedInstructorId.isNotEmpty) {
      availableCourses.value = await controller.getAvailableCoursesForInstructor(selectedInstructorId);
      if (!isEditing && availableCourses.isNotEmpty) {
        selectedCourseId = availableCourses.first['id'];
      }
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
                color: Colors.blue,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedInstructorId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Instructor',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey[700],
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
                    items: instructorController.instructors.map((instructor) {
                      return DropdownMenuItem<String>(
                        value: instructor.id,
                        child: Text(
                          instructor.name,
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        selectedInstructorId = value;
                        // Update available courses when instructor changes
                        availableCourses.value = await controller.getAvailableCoursesForInstructor(value);
                        if (availableCourses.isNotEmpty) {
                          selectedCourseId = availableCourses.first['id'];
                        } else {
                          selectedCourseId = '';
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Obx(() => DropdownButtonFormField<String>(
                    value: selectedCourseId.isEmpty ? null : selectedCourseId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Course',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey[700],
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
                    items: availableCourses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course['id'],
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            '${course['code']} - ${course['name']}\n${course['program']['name']}',
                            style: GoogleFonts.poppins(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedCourseId = value;
                      }
                    },
                  )),
                  const SizedBox(height: 16),
                  Text(
                    'Schedule Slots',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                    children: [
                      ...scheduleSlots.map((slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              '${slot.dayName} - ${slot.startTime} to ${slot.endTime}',
                              style: GoogleFonts.poppins(),
                            ),
                            subtitle: Text(
                              slot.classroom,
                              style: GoogleFonts.poppins(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => scheduleSlots.remove(slot),
                            ),
                          ),
                        ),
                      )).toList(),
                      TextButton.icon(
                        onPressed: () => _showAddScheduleSlotDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Add Schedule Slot',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
                  if (selectedInstructorId.isEmpty || selectedCourseId.isEmpty || scheduleSlots.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields and add at least one schedule slot'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final newAssignment = CourseAssignment(
                    id: assignment?.id ?? '',
                    instructorId: selectedInstructorId,
                    courseId: selectedCourseId,
                    scheduleSlots: scheduleSlots.toList(),
                    createdAt: assignment?.createdAt,
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    controller.updateAssignment(newAssignment);
                  } else {
                    controller.addAssignment(newAssignment);
                  }

                  Navigator.of(context).pop();
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
    } finally {
      // Clear controllers if dialog is dismissed
      if (!isEditing) {
        classroomController.clear();
        startTimeController.clear();
        endTimeController.clear();
        scheduleSlots.clear();
      }
    }
  }

  Future<void> _showAddScheduleSlotDialog(BuildContext context) async {
    selectedDayOfWeek = 1;
    selectedClassroom = controller.availableClassrooms.first;
    startTimeController.clear();
    endTimeController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Schedule Slot',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDayOfWeek,
                decoration: InputDecoration(
                  labelText: 'Day',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[700],
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
                items: List.generate(7, (index) => index + 1).map((day) {
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      CourseAssignment.daysOfWeek[day - 1],
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedDayOfWeek = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedClassroom,
                decoration: InputDecoration(
                  labelText: 'Classroom',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[700],
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
                items: controller.availableClassrooms.map((classroom) {
                  return DropdownMenuItem<String>(
                    value: classroom,
                    child: Text(
                      classroom,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedClassroom = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[700],
                  ),
                  hintText: 'HH:MM',
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[700],
                  ),
                  hintText: 'HH:MM',
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              final startTime = startTimeController.text.trim();
              final endTime = endTimeController.text.trim();

              if (startTime.isEmpty || endTime.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              scheduleSlots.add(ScheduleSlot(
                id: '',
                classroom: selectedClassroom,
                dayOfWeek: selectedDayOfWeek,
                startTime: startTime,
                endTime: endTime,
              ));

              Navigator.of(context).pop();
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
              'Add',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
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
            'Are you sure you want to delete this course assignment? This will also delete all associated schedule slots.',
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