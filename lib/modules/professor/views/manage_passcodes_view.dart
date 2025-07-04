import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/passcode_controller.dart';
import 'package:intl/intl.dart';

class ManagePasscodesView extends StatelessWidget {
  final String courseId;
  final String courseName;
  final List<String> scannedStudentIds;

  const ManagePasscodesView({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.scannedStudentIds,
  }) : super(key: key);

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final passcodeController = Get.find<PasscodeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Passcodes',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => passcodeController.generatePasscodes(
              courseId: courseId,
              studentIds: scannedStudentIds,
              validityMinutes: 5,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Course Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final totalPasscodes = passcodeController.passcodes.length;
                    final usedPasscodes = passcodeController.passcodes
                        .where((p) => p['is_used'] == true)
                        .length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Students: ${scannedStudentIds.length}',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        Text(
                          'Active Passcodes: $totalPasscodes',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        Text(
                          'Verified: $usedPasscodes',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // Passcodes List
          Expanded(
            child: Obx(() {
              if (passcodeController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (passcodeController.passcodes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No passcodes generated yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => passcodeController.generatePasscodes(
                          courseId: courseId,
                          studentIds: scannedStudentIds,
                          validityMinutes: 5,
                        ),
                        icon: const Icon(Icons.vpn_key),
                        label: const Text('Generate Passcodes'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: passcodeController.passcodes.length,
                itemBuilder: (context, index) {
                  final passcode = passcodeController.passcodes[index];
                  final isExpired = DateTime.now().isAfter(
                    DateTime.parse(passcode['expires_at']),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: passcode['is_used'] == true
                            ? Colors.green.shade100
                            : isExpired
                                ? Colors.red.shade100
                                : Colors.blue.shade100,
                        child: Icon(
                          passcode['is_used'] == true
                              ? Icons.check
                              : isExpired
                                  ? Icons.timer_off
                                  : Icons.timer,
                          color: passcode['is_used'] == true
                              ? Colors.green
                              : isExpired
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                      ),
                      title: Text(
                        passcode['student']['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: passcode['is_used'] == true
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passcode: ${passcode['passcode']}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              color: passcode['is_used'] == true
                                  ? Colors.grey
                                  : Colors.blue[700],
                            ),
                          ),
                          Text(
                            'Expires: ${_formatDateTime(passcode['expires_at'])}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isExpired ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => passcodeController.generatePasscodes(
          courseId: courseId,
          studentIds: scannedStudentIds,
          validityMinutes: 5,
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Generate New'),
      ),
    );
  }
} 