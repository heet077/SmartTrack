import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class LocationVerificationController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isWithinGeofence = false.obs;

  Future<bool> checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        error.value = 'Location services are disabled. Please enable location services.';
        Get.snackbar(
          'Location Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          error.value = 'Location permission denied. Please grant location permission.';
          Get.snackbar(
            'Location Error',
            error.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        error.value = 'Location permissions permanently denied. Please enable in settings.';
        Get.snackbar(
          'Location Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      return true;
    } catch (e) {
      error.value = 'Error checking location permission: $e';
      Get.snackbar(
        'Location Error',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  Future<bool> verifyLocation() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get admin settings for geofence
      final adminSettings = await _supabase
          .from('admin_settings')
          .select()
          .eq('id', 1)
          .single();

      debugPrint('Retrieved admin settings: $adminSettings');

      // Check if location check is enabled
      final locationCheckEnabled = adminSettings['location_check_enabled'] ?? false;
      if (!locationCheckEnabled) {
        debugPrint('Location check is disabled in admin settings');
        return true; // Skip location verification if disabled
      }

      // First check permissions
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return false;

      // Handle potential null or non-double values
      final dynamic rawLatitude = adminSettings['college_latitude'];
      final dynamic rawLongitude = adminSettings['college_longitude'];
      final dynamic rawRadius = adminSettings['geofence_radius'];

      // Convert to proper types
      final double? collegeLatitude = rawLatitude is int ? 
          rawLatitude.toDouble() : (rawLatitude as double?);
      final double? collegeLongitude = rawLongitude is int ? 
          rawLongitude.toDouble() : (rawLongitude as double?);
      final int? geofenceRadius = rawRadius is int ? 
          rawRadius : (rawRadius is double ? rawRadius.toInt() : null);

      // Validate settings
      if (collegeLatitude == null || collegeLongitude == null || geofenceRadius == null) {
        debugPrint('Invalid location settings - lat: $collegeLatitude, lng: $collegeLongitude, radius: $geofenceRadius');
        error.value = 'College location not properly configured. Please contact administrator.';
        Get.snackbar(
          'Location Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      // Get current location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      debugPrint('Current location - lat: ${position.latitude}, lng: ${position.longitude}');
      debugPrint('College location - lat: $collegeLatitude, lng: $collegeLongitude, radius: $geofenceRadius meters');

      // Calculate distance between current location and college
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        collegeLatitude,
        collegeLongitude
      );

      // Add detailed debug logging
      debugPrint('=== Location Verification Details ===');
      debugPrint('Current location: ${position.latitude}, ${position.longitude}');
      debugPrint('College location: $collegeLatitude, $collegeLongitude');
      debugPrint('Distance: ${(distance / 1000).toStringAsFixed(2)} km');
      debugPrint('Allowed radius: ${(geofenceRadius / 1000).toStringAsFixed(2)} km');
      debugPrint('Is within geofence: ${distance <= geofenceRadius}');
      debugPrint('Distance in meters: $distance');
      debugPrint('Geofence radius in meters: $geofenceRadius');
      debugPrint('===================================');

      // Check if within geofence radius (in meters)
      isWithinGeofence.value = distance <= geofenceRadius;

      if (!isWithinGeofence.value) {
        final distanceKm = (distance / 1000).toStringAsFixed(2);
        error.value = 'You are $distanceKm km away from college. You must be within ${(geofenceRadius/1000).toStringAsFixed(2)} km of the campus to mark attendance.';
        Get.snackbar(
          'Location Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      debugPrint('Location verified successfully');
      return true;
    } catch (e) {
      debugPrint('Error verifying location: $e');
      error.value = 'Failed to verify location: $e';
      Get.snackbar(
        'Location Error',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 