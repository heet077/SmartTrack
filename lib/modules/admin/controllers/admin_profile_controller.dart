import 'package:get/get.dart';
import '../../../services/supabase_service.dart';

class AdminProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<Map<String, dynamic>> adminData = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => loadAdminProfile());
  }

  Future<void> loadAdminProfile() async {
    if (isLoading.value) return; // Prevent multiple simultaneous loads
    
    try {
      isLoading.value = true;
      error.value = '';
      
      // Get the current user's email from Supabase Auth
      final currentUser = SupabaseService.client.auth.currentUser;
      
      if (currentUser == null) {
        error.value = 'No authenticated user found';
        return;
      }

      // Get admin data from the admins table
      final admin = await SupabaseService.getAdminByEmail(currentUser.email!);
      
      if (admin == null) {
        error.value = 'Admin profile not found';
        print('No admin profile found for email: ${currentUser.email}');
        return;
      }

      // Update the admin data
      adminData.value = {
        'id': admin['id'],
        'name': admin['name'],
        'email': admin['email'],
        // Add any other fields you want to display
      };

      print('Admin data loaded successfully: ${adminData.value}');
    } catch (e) {
      error.value = 'Failed to load admin profile';
      print('Error loading admin profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await loadAdminProfile();
  }
} 