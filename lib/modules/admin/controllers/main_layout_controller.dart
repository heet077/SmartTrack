import 'package:get/get.dart';
import 'attendance_controller.dart';

class MainLayoutController extends GetxController {
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with home page
    currentIndex.value = 0;
  }

  void changePage(int index) {
    currentIndex.value = index;
    
    // Initialize AttendanceController when navigating to the Reports page (index 1)
    if (index == 1 && !Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController());
    }
  }

  void logout() {
    Get.offAllNamed('/login');
  }
} 