import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _craftType = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _role = 'client';
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'إنشاء حساب',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoleSelector(),
              const SizedBox(height: 24),
              AppTextField(
                controller: _name,
                label: 'الاسم الكامل',
                hint: 'اسمك',
                validator: (v) => v!.isEmpty ? 'أدخل اسمك' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'البريد الإلكتروني',
                hint: 'email@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'أدخل البريد' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'كلمة المرور',
                hint: '••••••••',
                obscureText: _obscure,
                validator: (v) => v!.length < 6 ? 'على الأقل 6 أحرف' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'رقم الهاتف (اختياري)',
                hint: '0555 123 456',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _location,
                label: 'المدينة (اختياري)',
                hint: 'تلمسان',
              ),
              if (_role == 'artisan') ...[
                const SizedBox(height: 14),
                AppTextField(
                  controller: _craftType,
                  label: 'نوع الحرفة',
                  hint: 'فخار، شموع، نسيج...',
                  validator: (v) => _role == 'artisan' && v!.isEmpty
                      ? 'أدخل نوع حرفتك'
                      : null,
                ),
              ],
              Obx(
                () => ctrl.errorMsg.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          ctrl.errorMsg.value,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 28),
              Obx(
                () => AppButton(
                  label: 'إنشاء الحساب',
                  isLoading: ctrl.isLoading.value,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ctrl.register(
                        name: _name.text.trim(),
                        email: _email.text.trim(),
                        password: _password.text,
                        role: _role,
                        phone: _phone.text.trim().isEmpty
                            ? null
                            : _phone.text.trim(),
                        location: _location.text.trim().isEmpty
                            ? null
                            : _location.text.trim(),
                        craftType: _craftType.text.trim().isEmpty
                            ? null
                            : _craftType.text.trim(),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نوع الحساب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _roleOption(
                'client',
                'عميل',
                Icons.shopping_bag_outlined,
                'تسوق وتعلم',
              ),
              const SizedBox(width: 12),
              _roleOption(
                'artisan',
                'حرفي',
                Icons.handyman_outlined,
                'بع منتجاتك',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleOption(String role, String label, IconData icon, String sub) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
