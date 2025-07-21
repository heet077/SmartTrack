import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/student_passcode_controller.dart';
import '../controllers/location_verification_controller.dart';

class VerifyAttendanceView extends StatefulWidget {
  final String courseId;
  final String courseName;

  const VerifyAttendanceView({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<VerifyAttendanceView> createState() => _VerifyAttendanceViewState();
}

class _VerifyAttendanceViewState extends State<VerifyAttendanceView> {
  final StudentPasscodeController controller = Get.find<StudentPasscodeController>();
  final TextEditingController _passcodeController = TextEditingController();
  final LocationVerificationController _locationController = Get.put(LocationVerificationController());

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

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
      courseId: widget.courseId,
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          title: Text(
            'Verify Attendance',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.offAllNamed('/student/dashboard'),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.courseName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.qr_code_rounded,
                                size: 32,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Enter Passcode',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please enter the 6-digit passcode provided by your instructor',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _passcodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                hintText: 'Enter 6-digit passcode',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                letterSpacing: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Obx(() => SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value ? null : _verifyPasscode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Verify Attendance',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.error.value.isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[900], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.error.value,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red[900],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 