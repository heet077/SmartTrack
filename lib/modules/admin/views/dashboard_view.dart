import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => controller.isImporting.value
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Import Courses with Assignments',
                onPressed: controller.importCoursesFromCSV,
              ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.3,
                    children: [
                      _buildStatCard(
                        icon: Icons.school,
                        iconColor: Colors.blue,
                        title: 'Total Students',
                        value: controller.totalStudents,
                      ),
                      _buildStatCard(
                        icon: Icons.person,
                        iconColor: Colors.green,
                        title: 'Total Instructors',
                        value: controller.totalInstructors,
                      ),
                      _buildStatCard(
                        icon: Icons.book,
                        iconColor: Colors.purple,
                        title: 'Total Courses',
                        value: controller.totalCourses,
                      ),
                      _buildStatCard(
                        icon: Icons.school_outlined,
                        iconColor: Colors.orange,
                        title: 'Total Programs',
                        value: controller.totalPrograms,
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Management Options
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.school_outlined,
                title: 'Manage Programs',
                onTap: controller.navigateToManagePrograms,
              ),
              _buildActionButton(
                icon: Icons.book,
                title: 'Manage Courses',
                onTap: controller.navigateToManageCourses,
              ),
              _buildActionButton(
                icon: Icons.person,
                title: 'Manage Instructors',
                onTap: controller.navigateToManageInstructors,
              ),
              _buildActionButton(
                icon: Icons.groups,
                title: 'Manage Students',
                onTap: controller.navigateToManageStudents,
              ),
              _buildActionButton(
                icon: Icons.calendar_today,
                title: 'Assign Courses & Schedules',
                onTap: controller.navigateToAssignCourses,
              ),
              _buildActionButton(
                icon: Icons.checklist,
                title: 'View All Attendance',
                onTap: controller.navigateToViewAttendance,
              ),
              _buildActionButton(
                icon: Icons.settings,
                title: 'Settings',
                onTap: controller.navigateToSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required RxInt value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Obx(() => Text(
                    value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
} 