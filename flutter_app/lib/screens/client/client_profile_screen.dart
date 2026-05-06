import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart' as auth_svc;
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'orders_screen.dart';
import 'learn_screen.dart';
import 'favorites_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});
  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _api = Get.find<ApiService>();
  final _authSvc = Get.find<auth_svc.AuthService>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final user = _authSvc.user;
    _name.text = user?['name'] ?? '';
    _phone.text = user?['phone'] ?? '';
    _location.text = user?['location'] ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.patch('/auth/profile', data: {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'location': _location.text.trim(),
      });
      final user = Map<String, dynamic>.from(_authSvc.user ?? {});
      user['name'] = _name.text.trim();
      user['phone'] = _phone.text.trim();
      user['location'] = _location.text.trim();
      await _authSvc.saveSession(_authSvc.token!, user);
      setState(() => _editing = false);
      Get.snackbar('تم الحفظ', 'تم تحديث معلوماتك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight,
          colorText: AppColors.primaryDark);
    } catch (e) {
      Get.snackbar('خطأ', (e as dynamic).response?.data['message'] ?? 'حدث خطأ',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authSvc.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ملفي الشخصي',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(
              _editing ? 'إلغاء' : 'تعديل',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              _buildInfoCard(user),
              const SizedBox(height: 20),
              if (_editing) ...[
                _buildEditForm(),
                const SizedBox(height: 16),
                AppButton(
                  label: 'حفظ التغييرات',
                  isLoading: _loading,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
              ],
              _buildQuickLinks(),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user) {
    final name = user?['name'] ?? 'عميل';
    final email = user?['email'] ?? '';
    return Column(children: [
      CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          name[0],
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 36,
              fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 12),
      Text(name,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(email,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildInfoCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _infoRow(Icons.person_outline, 'الاسم', user?['name'] ?? '—'),
        _divider(),
        _infoRow(Icons.phone_outlined, 'الهاتف', user?['phone'] ?? '—'),
        _divider(),
        _infoRow(
            Icons.location_on_outlined, 'المدينة', user?['location'] ?? '—'),
        _divider(),
        _infoRow(Icons.badge_outlined, 'النوع', 'عميل'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
            textDirection: TextDirection.rtl),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.border);

  Widget _buildEditForm() {
    return Column(children: [
      AppTextField(
        controller: _name,
        label: 'الاسم الكامل',
        hint: 'اسمك',
        validator: (v) => v!.isEmpty ? 'أدخل اسمك' : null,
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _phone,
        label: 'رقم الهاتف',
        hint: '0555 123 456',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _location,
        label: 'المدينة',
        hint: 'تلمسان',
      ),
    ]);
  }

  Widget _buildQuickLinks() {
    final links = [
      {
        'icon': Icons.favorite_border,
        'label': 'المحفوظات',
        'sub': 'المنتجات التي حفظتها',
        'onTap': () => Get.to(() => const FavoritesScreen()),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'طلباتي',
        'sub': 'عرض سجل طلباتك',
        'onTap': () => Get.to(() => const OrdersScreen()),
      },
      {
        'icon': Icons.school_outlined,
        'label': 'الجلسات المحجوزة',
        'sub': 'جلسات التعلم التي حجزتها',
        'onTap': () => Get.to(() => const LearnScreen()),
      },
    ];
    return Column(
      children: links
          .map((l) => GestureDetector(
                onTap: l['onTap'] as VoidCallback,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(l['icon'] as IconData,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['label'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(l['sub'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ]),
                    const Spacer(),
                    const Icon(Icons.chevron_left, color: AppColors.textHint),
                  ]),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => Get.find<AuthController>().logout(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 18),
            SizedBox(width: 8),
            Text('تسجيل الخروج',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
