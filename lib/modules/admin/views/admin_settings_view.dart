import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_settings_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class AdminSettingsView extends GetView<AdminSettingsController> {
  const AdminSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Platform.isAndroid) ...[
                const Text(
                  'App Permissions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Storage Permission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Obx(() => Icon(
                              controller.hasStoragePermission.value
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: controller.hasStoragePermission.value
                                  ? Colors.green
                                  : Colors.red,
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
              const Text(
                          'Required for downloading attendance reports',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() => controller.hasStoragePermission.value
                            ? const Text(
                                'Permission granted',
                                style: TextStyle(
                                  color: Colors.green,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: controller.requestStoragePermission,
                                child: const Text('Grant Storage Permission'),
                              )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'QR Code Settings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code Duration',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current duration: ${controller.qrCodeDurationInMinutes} minutes',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showDurationPicker(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Change Duration',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Location Settings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Location Check',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: controller.locationCheckEnabled.value,
                            onChanged: (value) => controller.toggleLocationCheck(value),
                          ),
                        ],
                      ),
                      Text(
                        'When enabled, students must be within the specified radius of the college location to mark attendance',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'College Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: controller.tempLatitude.toString(),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                helperText: 'Valid range: -90 to 90',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              onChanged: controller.updateTempLatitude,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: controller.tempLongitude.toString(),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                helperText: 'Valid range: -180 to 180',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              onChanged: controller.updateTempLongitude,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Geofence Radius',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current radius: ${controller.geofenceRadius} meters',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: controller.tempRadius.toString(),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Radius (meters)',
                                border: OutlineInputBorder(),
                                helperText: 'Enter a positive number (e.g., 100)',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: controller.updateTempRadius,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => controller.saveLocationSettings(),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.green,
                              ),
                              child: Text(
                                'Save Location Settings',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showDurationPicker(BuildContext context) {
    final textController = TextEditingController(
      text: controller.qrCodeDurationInMinutes.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set QR Code Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration in minutes:'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Duration in minutes',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final duration = int.tryParse(value);
                if (duration != null && duration > 0) {
                  controller.updateQrCodeDurationFromMinutes(duration);
                  Get.back();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final duration = int.tryParse(textController.text);
              if (duration != null && duration > 0) {
                controller.updateQrCodeDurationFromMinutes(duration);
                Get.back();
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a valid number of minutes',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 