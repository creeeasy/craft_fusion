import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthController extends GetxController {
  final _api = Get.find<ApiService>();
  final _auth = Get.find<AuthService>();

  final isLoading = false.obs;
  final errorMsg = ''.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    errorMsg.value = '';
    try {
      final res = await _api
          .post('/auth/login', data: {'email': email, 'password': password});
      await _auth.saveSession(res.data['token'], res.data['user']);
      _navigateByRole(res.data['user']['role']);
    } catch (e) {
      errorMsg.value = _extractError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? location,
    String? craftType,
    String? bio,
  }) async {
    isLoading.value = true;
    errorMsg.value = '';
    try {
      final res = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'location': location,
        'craft_type': craftType,
        'bio': bio,
      });
      await _auth.saveSession(res.data['token'], res.data['user']);
      if (role == 'artisan') {
        Get.snackbar('تم التسجيل', 'حسابك قيد المراجعة من الإدارة',
            snackPosition: SnackPosition.BOTTOM);
        Get.offAllNamed(AppRoutes.login);
      } else {
        _navigateByRole(role);
      }
    } catch (e) {
      errorMsg.value = _extractError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'client':
        Get.offAllNamed(AppRoutes.clientHome);
        break;
      case 'artisan':
        Get.offAllNamed(AppRoutes.artisanDashboard);
        break;
      case 'admin':
        Get.offAllNamed(AppRoutes.adminDashboard);
        break;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  String _extractError(dynamic e) {
    try {
      return e.response?.data['message'] ?? 'حدث خطأ، حاول مجدداً';
    } catch (_) {
      return 'تعذر الاتصال بالخادم';
    }
  }
}
