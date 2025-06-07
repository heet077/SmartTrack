import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _qrValidityKey = 'qr_validity_minutes';
  static const String _wifiCheckKey = 'wifi_check_enabled';
  
  final RxInt qrValidityMinutes = 5.obs;
  final RxBool wifiCheckEnabled = false.obs;
  
  late final SharedPreferences _prefs;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      qrValidityMinutes.value = _prefs.getInt(_qrValidityKey) ?? 5;
      wifiCheckEnabled.value = _prefs.getBool(_wifiCheckKey) ?? false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> setQRValidityMinutes(int minutes) async {
    try {
      await _prefs.setInt(_qrValidityKey, minutes);
      qrValidityMinutes.value = minutes;
      Get.snackbar(
        'Success',
        'QR code validity updated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update QR code validity',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> toggleWifiCheck(bool enabled) async {
    try {
      await _prefs.setBool(_wifiCheckKey, enabled);
      wifiCheckEnabled.value = enabled;
      Get.snackbar(
        'Success',
        'Wi-Fi check ${enabled ? 'enabled' : 'disabled'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update Wi-Fi check setting',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
} 