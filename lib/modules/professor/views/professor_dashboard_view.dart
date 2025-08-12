import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/professor_controller.dart';
import '../models/professor_model.dart';
import 'qr_attendance_view.dart';
import '../controllers/lecture_session_controller.dart';
import 'start_lecture_view.dart';
import '../models/assigned_course.dart' as course_model;
import '../models/lecture_session.dart';
import 'reschedule_lecture_dialog.dart';
import '../controllers/lecture_reschedule_controller.dart';

class ProfessorDashboardView extends GetView<ProfessorController> {
  const ProfessorDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final professor = controller.currentProfessor.value;
        if (professor == null) {
          return Center(
            child: Text(
              'No professor data found',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          );
        }

        return _buildHomeView(professor);
      }),
    );
  }

  Widget _buildHomeView(Professor professor) {
    return Column(
      children: [
        const SafeArea(child: SizedBox.shrink()),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            return RefreshIndicator(
              onRefresh: controller.loadProfessorData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      color: Colors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    professor.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Text(
                                  professor.name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildHeaderStat(
                                'Courses',
                                '${controller.assignedCourses.length}',
                                Icons.book_outlined,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _buildHeaderStat(
                                'Today\'s Classes',
                                '${controller.assignedCourses.where((c) => c.dayOfWeek == DateTime.now().weekday).length}',
                                Icons.calendar_today_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Content Container
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Today's Lectures
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Lectures',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: controller.getTodayLectures(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _buildErrorCard('Error: ${snapshot.error}');
                                    }

                                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return _buildEmptyCard('No lectures scheduled for today');
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        final lecture = snapshot.data![index];
                                        if (lecture == null) return const SizedBox.shrink();
                                        
                                        final courseData = lecture['instructor_course_assignments']['course'];
                                        if (courseData == null) return const SizedBox.shrink();
                                        
                                        return Card(
                                          elevation: 0,
                                          margin: const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Icon(Icons.class_outlined, 
                                                        color: Colors.blue,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            courseData['code'] ?? 'Unknown Code',
                                                            style: GoogleFonts.poppins(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          Text(
                                                            courseData['name'] ?? 'Unknown Course',
                                                            style: GoogleFonts.poppins(
                                                              color: Colors.grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(Icons.access_time, 
                                                                size: 16, 
                                                                color: Colors.grey[600]
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                lecture['start_time'] ?? 'TBD',
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors.grey[600],
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 16),
                                                              Icon(Icons.room, 
                                                                size: 16, 
                                                                color: Colors.grey[600]
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                'Room ${lecture['classroom'] ?? 'TBD'}',
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors.grey[600],
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton.icon(
                                                      onPressed: () {
                                                        // Parse the start time string to DateTime
                                                        final now = DateTime.now();
                                                        final timeParts = (lecture['start_time'] as String).split(':');
                                                        final startTime = DateTime(
                                                          now.year,
                                                          now.month,
                                                          now.day,
                                                          int.parse(timeParts[0]),
                                                          int.parse(timeParts[1]),
                                                        );
                                                        
                                                        // Parse the end time string to DateTime
                                                        final endTimeParts = (lecture['end_time'] as String).split(':');
                                                        final endTime = DateTime(
                                                          now.year,
                                                          now.month,
                                                          now.day,
                                                          int.parse(endTimeParts[0]),
                                                          int.parse(endTimeParts[1]),
                                                        );

                                                        final lectureSession = LectureSession(
                                                          id: lecture['id'],
                                                          scheduleId: lecture['id'],
                                                          courseId: courseData['id'],
                                                          instructorId: lecture['instructor_course_assignments']['instructor_id'],
                                                          courseCode: courseData['code'],
                                                          courseName: courseData['name'],
                                                          classroom: lecture['classroom'],
                                                          startTime: startTime,
                                                          endTime: endTime,
                                                        );
                                                        final rescheduleController = Get.put(LectureRescheduleController());
                                                        Get.dialog(
                                                          RescheduleLectureDialog(
                                                            lecture: lectureSession,
                                                            controller: rescheduleController, lectureId: '',
                                                          ),
                                                        );
                                                      },
                                                      icon: const Icon(Icons.calendar_today),
                                                      label: Text(
                                                        'Reschedule',
                                                        style: GoogleFonts.poppins(),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // My Courses
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Courses',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Obx(() {
                                  if (controller.assignedCourses.isEmpty) {
                                    return _buildEmptyCard('No courses assigned');
                                  }

                                  final uniqueCourses = controller.assignedCourses.fold<Map<String, course_model.Course>>(
                                    {},
                                    (map, assignedCourse) {
                                      if (!map.containsKey(assignedCourse.courseId)) {
                                        map[assignedCourse.courseId] = assignedCourse.course;
                                      }
                                      return map;
                                    },
                                  );

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.3,
                                    ),
                                    itemCount: uniqueCourses.length,
                                    itemBuilder: (context, index) {
                                      final course = uniqueCourses.values.toList()[index];
                                      return Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(Icons.book_outlined,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    course.code,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    course.name,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Start Lecture Button
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Get.to(() => StartLectureView());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Start Lecture',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[900],
            ),
          ),
        ),
      ),
    );
  }
} 