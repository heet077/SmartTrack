import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_preview/device_preview.dart';
import 'routes/app_routes.dart';
import 'core/bindings/app_bindings.dart';
import 'services/supabase_service.dart';
import 'modules/admin/controllers/admin_settings_controller.dart';
import 'package:retry/retry.dart';

void main() async {
  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase connection with retries
    await retry(
          () => SupabaseService.initialize(),
      maxAttempts: 3,
      delayFactor: const Duration(milliseconds: 500),
      retryIf: (e) => e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('ClientException'),
      onRetry: (e) async {
        debugPrint('Retrying Supabase initialization: $e');
      },
    );

    // Run the app with DevicePreview (enabled only in debug)
    runApp(
      DevicePreview(
        enabled: !bool.fromEnvironment('dart.vm.product'),
        builder: (context) => const MyApp(),
      ),
    );

    // Initialize admin settings controller
    if (!Get.isRegistered<AdminSettingsController>()) {
      Get.put(AdminSettingsController());
    }
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show error UI if initialization fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to connect to server',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.\n\nError: ${e.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      useInheritedMediaQuery: true, // Required for DevicePreview
      locale: DevicePreview.locale(context), // Device locale
      builder: DevicePreview.appBuilder, // Wrap widgets for preview

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.closeAllSnackbars();
        });
      },
    );
  }
}
