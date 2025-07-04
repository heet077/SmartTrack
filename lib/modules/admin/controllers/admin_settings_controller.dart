import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AdminSettingsController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt qrCodeDuration = 300.obs; // Default 5 minutes in seconds
  
  // Location settings
  final RxDouble collegeLatitude = 0.0.obs;
  final RxDouble collegeLongitude = 0.0.obs;
  final RxInt geofenceRadius = 100.obs; // Default 100 meters
  final RxBool locationCheckEnabled = false.obs; // Added location check toggle
  
  // Temporary values for editing
  final RxDouble tempLatitude = 0.0.obs;
  final RxDouble tempLongitude = 0.0.obs;
  final RxInt tempRadius = 100.obs;

  final RxBool hasStoragePermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('AdminSettingsController: onInit called');
    loadSettings();
    checkPermissions();
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
        final latitude = response['college_latitude'];
        final longitude = response['college_longitude'];
        final radius = response['geofence_radius'];
        final locationCheck = response['location_check_enabled'];
        
        debugPrint('AdminSettingsController: Retrieved settings - duration: $duration, lat: $latitude, lng: $longitude, radius: $radius');
        
        if (duration != null) qrCodeDuration.value = duration;
        if (latitude != null) {
          collegeLatitude.value = latitude;
          tempLatitude.value = latitude;
        }
        if (longitude != null) {
          collegeLongitude.value = longitude;
          tempLongitude.value = longitude;
        }
        if (radius != null) {
          geofenceRadius.value = radius;
          tempRadius.value = radius;
        }
        if (locationCheck != null) {
          locationCheckEnabled.value = locationCheck;
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
      debugPrint('AdminSettingsController: Starting to update QR duration to $seconds seconds');

      await _updateSettings({'qr_code_duration': seconds});
      qrCodeDuration.value = seconds;
      
      Get.snackbar(
        'Success',
        'QR code duration updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _handleError(e, 'updating QR duration');
    } finally {
      isLoading.value = false;
    }
  }

  void updateTempLatitude(String value) {
    final lat = double.tryParse(value);
    if (lat != null && lat >= -90 && lat <= 90) {
      tempLatitude.value = lat;
    }
  }

  void updateTempLongitude(String value) {
    final lng = double.tryParse(value);
    if (lng != null && lng >= -180 && lng <= 180) {
      tempLongitude.value = lng;
    }
  }

  void updateTempRadius(String value) {
    final radius = int.tryParse(value);
    if (radius != null && radius > 0) {
      tempRadius.value = radius;
    }
  }

  bool validateLocationSettings() {
    if (tempLatitude.value < -90 || tempLatitude.value > 90) {
      error.value = 'Latitude must be between -90 and 90';
      return false;
    }
    if (tempLongitude.value < -180 || tempLongitude.value > 180) {
      error.value = 'Longitude must be between -180 and 180';
      return false;
    }
    if (tempRadius.value <= 0) {
      error.value = 'Geofence radius must be greater than 0';
      return false;
    }
    return true;
  }

  Future<void> saveLocationSettings() async {
    try {
      if (!validateLocationSettings()) {
        Get.snackbar(
          'Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      error.value = '';
      
      await _updateSettings({
        'college_latitude': tempLatitude.value,
        'college_longitude': tempLongitude.value,
        'geofence_radius': tempRadius.value,
      });

      // Update the actual values after successful save
      collegeLatitude.value = tempLatitude.value;
      collegeLongitude.value = tempLongitude.value;
      geofenceRadius.value = tempRadius.value;
      
      Get.snackbar(
        'Success',
        'Location settings saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _handleError(e, 'saving location settings');
      // Reset temp values to current values on error
      tempLatitude.value = collegeLatitude.value;
      tempLongitude.value = collegeLongitude.value;
      tempRadius.value = geofenceRadius.value;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLocationCheck(bool enabled) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _updateSettings({'location_check_enabled': enabled});
      locationCheckEnabled.value = enabled;

      Get.snackbar(
        'Success',
        'Location check ${enabled ? 'enabled' : 'disabled'} successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _handleError(e, 'updating location check setting');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
      // First check if settings exist
      final existingSettings = await _supabase
          .from('admin_settings')
          .select('id')
          .eq('id', 1)
          .maybeSingle();

    updates['updated_at'] = DateTime.now().toIso8601String();

      if (existingSettings == null) {
        // If settings don't exist, insert new settings
        debugPrint('AdminSettingsController: Creating new settings record');
      updates['id'] = 1;
      updates['created_at'] = DateTime.now().toIso8601String();
        await _supabase
            .from('admin_settings')
          .insert(updates);
      } else {
        // If settings exist, update them
        debugPrint('AdminSettingsController: Updating existing settings');
        await _supabase
            .from('admin_settings')
          .update(updates)
            .eq('id', 1);
      }
  }

  void _handleError(dynamic e, String action) {
    debugPrint('AdminSettingsController: Error $action: $e');
    if (e is PostgrestException) {
      debugPrint('AdminSettingsController: Supabase error code: ${e.code}');
      debugPrint('AdminSettingsController: Supabase error details: ${e.details}');
    }
    error.value = 'Failed to $action: $e';
    Get.snackbar(
      'Error',
      'Failed to $action: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      hasStoragePermission.value = status.isGranted;
    }
  }

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      hasStoragePermission.value = status.isGranted;
      
      if (status.isGranted) {
        Get.snackbar(
          'Success',
          'Storage permission granted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
      Get.snackbar(
          'Permission Required',
          'Storage permission is needed for downloading reports',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('OPEN SETTINGS', style: TextStyle(color: Colors.white)),
          ),
      );
      }
    }
  }
} 