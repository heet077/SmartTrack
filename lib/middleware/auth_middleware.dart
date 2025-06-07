import 'package:get/get.dart';
import '../services/supabase_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    final currentUser = SupabaseService.client.auth.currentUser;
    
    // If trying to access a protected route and not logged in
    if (currentUser == null && !route.location!.startsWith('/login')) {
      return GetNavConfig.fromRoute('/login');
    }

    // If trying to access login while already logged in
    if (currentUser != null && route.location!.startsWith('/login')) {
      return GetNavConfig.fromRoute('/admin/dashboard');
    }

    return await super.redirectDelegate(route);
  }
} 