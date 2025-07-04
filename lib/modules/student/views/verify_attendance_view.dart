import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_passcode_controller.dart';
import '../controllers/location_verification_controller.dart';

class VerifyAttendanceView extends GetView<StudentPasscodeController> {
  final String courseId;
  final String courseName;
  final TextEditingController _passcodeController = TextEditingController();
  final LocationVerificationController _locationController = Get.put(LocationVerificationController());

  VerifyAttendanceView({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  Future<void> _verifyPasscode() async {
    final passcode = _passcodeController.text.trim();
    
    if (passcode.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the passcode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // First verify location
    final isLocationValid = await _locationController.verifyLocation();
    if (!isLocationValid) {
      Get.offAllNamed('/student/dashboard');
      return;
    }

    // Verify passcode
    final success = await controller.verifyPasscode(
      courseId: courseId,
      passcode: passcode,
    );

    if (success) {
      // Show success message
      Get.snackbar(
        'Success',
        'Attendance marked successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Wait for snackbar to be visible before navigation
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate back to dashboard
      Get.offAllNamed('/student/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed('/student/dashboard');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Verify Attendance',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.offAllNamed('/student/dashboard'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Passcode',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passcodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit passcode',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  counterText: '',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : _verifyPasscode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Verify Attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              )),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.error.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.error.value,
                      style: GoogleFonts.poppins(
                        color: Colors.red[900],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
} 