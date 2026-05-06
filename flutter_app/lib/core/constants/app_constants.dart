import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppColors {
  // 🌰 PRIMARY (Main Brown Identity)
  static const primary = Color(0xFF6B3E26); // rich brown
  static const primaryDark = Color(0xFF4A2A1A); // deep brown
  static const primaryLight = Color(0xFFF3E8E2); // soft beige

  // ✨ ACCENT (Gold / Craft Feel)
  static const accent = Color(0xFFD4A373); // warm gold
  static const accentLight = Color(0xFFF6E6D8); // light gold/beige

  // 🏺 SPECIAL (Craft / Premium tones)
  static const sponsored = Color(0xFFB08968); // clay brown
  static const gold = Color(0xFFD4A373); // premium gold
  static const silver = Color(0xFF8D8D8D); // neutral silver

  // 🧱 BACKGROUND SYSTEM
  static const background =
      Color(0xFFFAF7F5); // warm background (not cold white)
  static const surface = Color(0xFFFFFFFF); // cards

  // 📝 TEXT COLORS
  static const textPrimary = Color(0xFF2D1B12); // dark brown (instead of black)
  static const textSecondary = Color(0xFF7C6A5D); // muted brown-gray
  static const textHint = Color(0xFFA89A90); // soft hint

  // 🔲 UI ELEMENTS
  static const border = Color(0xFFEADFD7); // soft beige border

  // 🚨 STATUS
  static const error = Color(0xFFC44536); // warm red
  static const success = Color(0xFF7A9E7E); // muted green (still needed)
}

class AppStrings {
  static const appName = 'Craft Fusion';
  static const tagline = 'منصة الحرف المحلية';
  static const baseUrl =
      'https://craft-fusion.onrender.com/api'; // Android emulator
}

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const clientHome = '/client/home';
  static const productDetail = '/product/detail';
  static const artisanProfile = '/artisan/profile';
  static const cart = '/cart';
  static const orders = '/orders';
  static const learn = '/learn';
  static const artisanDashboard = '/artisan/dashboard';
  static const adminDashboard = '/admin/dashboard';
}
