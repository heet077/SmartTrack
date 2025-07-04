import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/student_attendance_marking_controller.dart';
import '../controllers/location_verification_controller.dart';

class ScanQRView extends StatefulWidget {
  const ScanQRView({Key? key}) : super(key: key);

  @override
  State<ScanQRView> createState() => _ScanQRViewState();
}

class _ScanQRViewState extends State<ScanQRView> {
  final MobileScannerController controller = MobileScannerController();
  String? result;
  bool isFlashOn = false;
  bool isProcessing = false;
  bool isCheckingLocation = true;
  final attendanceController = Get.put(StudentAttendanceMarkingController());
  final locationController = Get.put(LocationVerificationController());

  @override
  void initState() {
    super.initState();
    // Verify location before showing the scanner
    _verifyLocationAndProceed();
  }

  Future<void> _verifyLocationAndProceed() async {
    setState(() {
      isCheckingLocation = true;
    });

    final isLocationValid = await locationController.verifyLocation();
    
    if (!isLocationValid && mounted) {
      // If location is invalid, go back to dashboard
      Get.offAllNamed('/student/dashboard');
    } else if (mounted) {
      // Only show scanner if location is valid
      setState(() {
        isCheckingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed('/student/dashboard');
        return false;
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.offAllNamed('/student/dashboard'),
        ),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
                controller.toggleTorch();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
            if (!isCheckingLocation) MobileScanner(
            controller: controller,
              onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isProcessing) {
                final String code = barcodes.first.rawValue ?? '';
                setState(() {
                  result = code;
                  isProcessing = true;
                });

                  // Verify location before processing QR code
                  final isLocationValid = await locationController.verifyLocation();
                  if (!isLocationValid) {
                    setState(() {
                      isProcessing = false;
                    });
                    // If location becomes invalid while scanning, go back to dashboard
                    Get.offAllNamed('/student/dashboard');
                    return;
                  }

                // Process the QR code data
                attendanceController.markAttendance(code);
              }
            },
          ),
            if (isCheckingLocation)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Verifying Location...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isCheckingLocation) Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Stack(
              children: [
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            if (!isCheckingLocation) Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                          color: Colors.white,
                        ),
                  const SizedBox(height: 16),
                  Text(
                    'Position the QR code within the frame',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure the code is well-lit and in focus',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
          ),
                Obx(() {
                  if (attendanceController.isLoading.value) {
                    return Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                        children: [
                      const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                        'Processing QR Code...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                          color: Colors.white,
                            ),
                          ),
                        ],
                  ),
                      ),
                    );
                  }

                  if (attendanceController.error.value.isNotEmpty) {
                    return Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.all(24),
                child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            attendanceController.error.value,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                          color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isProcessing = false;
                            result = null;
                              attendanceController.error.value = '';
                              });
                            // Resume scanning
                            controller.start();
                            },
                            style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.poppins(
                              color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }),
        ],
        ),
      ),
    );
  }
} 