import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService extends GetxService {
  final _user = Rxn<Map<String, dynamic>>();
  final _token = RxnString();

  Map<String, dynamic>? get user => _user.value;
  String? get token => _token.value;
  bool get isLoggedIn => _token.value != null;
  String get role => _user.value?['role'] ?? '';

  // Called from main() before runApp so routing works on first frame
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token.value = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) _user.value = jsonDecode(userStr);
  }

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
    _token.value = token;
    _user.value = user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token.value = null;
    _user.value = null;
  }
}
