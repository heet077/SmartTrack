import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';
import 'core/bindings/app_bindings.dart';
import 'services/supabase_service.dart';
import 'modules/admin/controllers/admin_settings_controller.dart';

void main() async {
  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Supabase connection
    await SupabaseService.initialize();
    
    // Run the app
    runApp(const MyApp());
    
    // Initialize admin settings controller
    if (!Get.isRegistered<AdminSettingsController>()) {
      Get.put(AdminSettingsController());
    }
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
      initialBinding: AppBindings(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      popGesture: true,
      smartManagement: SmartManagement.full,
      navigatorKey: Get.key,
      navigatorObservers: [GetObserver()],
      onInit: () {
        // Clear any existing overlays when app starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.closeAllSnackbars();
        });
      },
      builder: (context, child) {
        // Ensure proper MediaQuery handling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

