import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AdminSettingsController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt qrCodeDuration = 300.obs; // Default 5 minutes in seconds

  @override
  void onInit() {
    super.onInit();
    debugPrint('AdminSettingsController: onInit called');
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      isLoading.value = true;
      error.value = '';
      debugPrint('AdminSettingsController: Loading settings from database...');

      // Try to get existing settings
      final response = await _supabase
          .from('admin_settings')
          .select('*')
          .eq('id', 1)
          .maybeSingle();

      debugPrint('AdminSettingsController: Raw Supabase response: $response');

      if (response != null) {
        final duration = response['qr_code_duration'];
        debugPrint('AdminSettingsController: Retrieved duration from DB: $duration');
        
        if (duration != null) {
          qrCodeDuration.value = duration;
          debugPrint('AdminSettingsController: Set QR duration to ${qrCodeDuration.value} seconds (${qrCodeDuration.value ~/ 60} minutes)');
        } else {
          debugPrint('AdminSettingsController: Warning - qr_code_duration is null in database');
        }
      } else {
        debugPrint('AdminSettingsController: No settings found, will be created on first update');
      }
    } catch (e) {
      debugPrint('AdminSettingsController: Detailed error in loadSettings: $e');
      if (e is PostgrestException) {
        debugPrint('AdminSettingsController: Supabase error code: ${e.code}');
        debugPrint('AdminSettingsController: Supabase error details: ${e.details}');
      }
      error.value = 'Failed to load settings: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQrCodeDurationFromMinutes(int minutes) async {
    try {
      debugPrint('AdminSettingsController: Updating QR duration from $minutes minutes');
      final seconds = minutes * 60;
      await updateQrCodeDuration(seconds);
    } catch (e) {
      debugPrint('AdminSettingsController: Error updating QR duration from minutes: $e');
      error.value = 'Failed to update settings: $e';
      Get.snackbar(
        'Error',
        'Failed to update settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  int get qrCodeDurationInMinutes => (qrCodeDuration.value / 60).round();

  Future<void> updateQrCodeDuration(int seconds) async {
    try {
      isLoading.value = true;
      error.value = '';
      debugPrint('AdminSettingsController: Starting to update QR duration to $seconds seconds (${seconds ~/ 60} minutes)');

      // First check if settings exist
      final existingSettings = await _supabase
          .from('admin_settings')
          .select('id')
          .eq('id', 1)
          .maybeSingle();

      if (existingSettings == null) {
        // If settings don't exist, insert new settings
        debugPrint('AdminSettingsController: Creating new settings record');
        await _supabase
            .from('admin_settings')
            .insert({
              'id': 1,
              'qr_code_duration': seconds,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      } else {
        // If settings exist, update them
        debugPrint('AdminSettingsController: Updating existing settings');
        await _supabase
            .from('admin_settings')
            .update({
              'qr_code_duration': seconds,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', 1);
      }

      // Verify the update
      final verifyResponse = await _supabase
          .from('admin_settings')
          .select('qr_code_duration')
          .eq('id', 1)
          .single();
      
      debugPrint('AdminSettingsController: Verification read from database: $verifyResponse');
      
      if (verifyResponse['qr_code_duration'] == seconds) {
        qrCodeDuration.value = seconds;
        debugPrint('AdminSettingsController: Successfully updated QR duration to $seconds seconds (${seconds ~/ 60} minutes)');
        
        Get.snackbar(
          'Success',
          'QR code duration updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Verification failed: Database value does not match expected value');
      }
    } catch (e) {
      debugPrint('AdminSettingsController: Detailed error updating settings: $e');
      if (e is PostgrestException) {
        debugPrint('AdminSettingsController: Supabase error code: ${e.code}');
        debugPrint('AdminSettingsController: Supabase error details: ${e.details}');
      }
      error.value = 'Failed to update settings: $e';
      Get.snackbar(
        'Error',
        'Failed to update settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 