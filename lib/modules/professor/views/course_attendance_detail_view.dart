import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/assigned_course.dart' as course_model;
import '../controllers/professor_controller.dart';

class CourseAttendanceDetailView extends StatelessWidget {
  final course_model.AssignedCourse course;
  
  const CourseAttendanceDetailView({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Attendance',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              course.course.code,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Implement date selection
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceStats('Total', '45', Colors.grey.shade700),
                _buildAttendanceStats('Present', '42', Colors.green),
                _buildAttendanceStats('Absent', '3', Colors.red),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'QR Scanned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.black54, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'OTP Verified',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 3, // Replace with actual student count
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // Sample student data - replace with actual data
                final students = [
                  {
                    'name': 'Alice Johnson',
                    'id': '2023001',
                    'status': 'present',
                    'avatar': 'https://i.pravatar.cc/150?img=1',
                  },
                  {
                    'name': 'Bob Smith',
                    'id': '2023002',
                    'status': 'present',
                    'avatar': 'https://i.pravatar.cc/150?img=2',
                  },
                  {
                    'name': 'Carol White',
                    'id': '2023003',
                    'status': 'pending',
                    'avatar': 'https://i.pravatar.cc/150?img=3',
                  },
                ];

                final student = students[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(student['avatar']!),
                  ),
                  title: Text(
                    student['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(student['id']!),
                  trailing: Icon(
                    student['status'] == 'present'
                        ? Icons.check_circle
                        : Icons.access_time,
                    color: student['status'] == 'present'
                        ? Colors.green
                        : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 