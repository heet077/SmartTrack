import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/professor_controller.dart';
import '../../controllers/attendance_controller.dart';
import 'take_attendance.dart';

class ProfessorDashboard extends StatelessWidget {
  final ProfessorController controller = Get.put(ProfessorController());
  final AttendanceController attendanceController = Get.put(AttendanceController());

  void _navigateToAttendance(String courseId, String courseName) async {
    await attendanceController.loadStudentsForCourse(courseId, courseName);
    Get.to(() => TakeAttendanceScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              controller.supabase.auth.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${controller.error.value}',
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () => controller.refreshData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final professor = controller.currentProfessor.value;
        if (professor == null) {
          return const Center(child: Text('No professor data found'));
        }

        // Sort courses by day of week and start time
        final sortedCourses = List.from(professor.assignedCourses)
          ..sort((a, b) {
            int dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
            if (dayCompare != 0) return dayCompare;
            return a.startTime.compareTo(b.startTime);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professor Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Professor Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Name'),
                        subtitle: Text(professor.name),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(professor.email),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Course Schedule Section
              const Text(
                'Course Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (sortedCourses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No courses assigned yet'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedCourses.length,
                  itemBuilder: (context, index) {
                    final assignment = sortedCourses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(assignment.course.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${assignment.course.code}'),
                            Text('Semester: ${assignment.course.semester}'),
                            Text('Day: ${assignment.dayName}'),
                            Text('Time: ${assignment.startTime} - ${assignment.endTime}'),
                            Text('Classroom: ${assignment.classroom}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people),
                              onPressed: () => _navigateToAttendance(
                                assignment.course.id,
                                assignment.course.name,
                              ),
                              tooltip: 'Take Attendance',
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Get.toNamed('/course/${assignment.course.id}');
                              },
                              tooltip: 'Course Details',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
} 