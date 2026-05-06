import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'core/constants/app_constants.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/favorites_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/client/home_screen.dart';
import 'screens/artisan/artisan_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Get.putAsync(() async => ApiService());

  final authService = AuthService();
  await authService.loadFromPrefs();
  Get.put(authService);

  Get.lazyPut(() => AuthController(), fenix: true);
  Get.lazyPut(() => ProductController(), fenix: true);
  Get.lazyPut(() => OrderController(), fenix: true);
  Get.lazyPut(() => FavoritesController(), fenix: true);

  runApp(const NaamAyaApp());
}

class NaamAyaApp extends StatelessWidget {
  const NaamAyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // Always start at splash — it handles routing
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(
            name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
        GetPage(
            name: AppRoutes.clientHome, page: () => const ClientHomeScreen()),
        GetPage(
            name: AppRoutes.artisanDashboard,
            page: () => const ArtisanDashboardScreen()),
        GetPage(
            name: AppRoutes.adminDashboard,
            page: () => const AdminDashboardScreen()),
      ],
    );
  }
}
