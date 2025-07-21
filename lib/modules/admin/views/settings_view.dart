import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/main_layout_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<MainLayoutController>();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'General Settings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
            color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
              ),
              ],
          ),
            child: Column(
              children: [
                ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.wifi,
                      color: Colors.blue,
                ),
              ),
                  title: Text(
                    'Wi-Fi Check',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              trailing: Obx(() => Switch(
                value: controller.wifiCheckEnabled.value,
                onChanged: controller.toggleWifiCheck,
                activeColor: Colors.blue,
              )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: mainController.logout,
              icon: const Icon(Icons.logout),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showQRValidityDialog(BuildContext context) async {
    final TextEditingController textController = TextEditingController(
      text: controller.qrValidityMinutes.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Validity'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'Enter validity duration in minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(textController.text);
              if (minutes != null && minutes > 0) {
                controller.setQRValidityMinutes(minutes);
                Get.back();
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a valid number of minutes',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    textController.dispose();
  }
} 