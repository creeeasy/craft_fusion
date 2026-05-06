import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart' as auth_svc;
import '../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _api = Get.find<ApiService>();
  final _authSvc = Get.find<auth_svc.AuthService>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _craftType = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _savingLocation = false;

  // Algerian city presets for quick pick
  final _cityPresets = const [
    {'name': 'تلمسان', 'lat': '34.8828', 'lng': '-1.3167'},
    {'name': 'وهران', 'lat': '35.6969', 'lng': '-0.6331'},
    {'name': 'الجزائر', 'lat': '36.7525', 'lng': '3.0420'},
    {'name': 'قسنطينة', 'lat': '36.3650', 'lng': '6.6147'},
    {'name': 'عنابة', 'lat': '36.9000', 'lng': '7.7667'},
    {'name': 'سطيف', 'lat': '36.1903', 'lng': '5.4103'},
    {'name': 'بجاية', 'lat': '36.7509', 'lng': '5.0564'},
    {'name': 'بسكرة', 'lat': '34.8500', 'lng': '5.7333'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _api.get('/auth/me');
      final user = res.data['user'] as Map<String, dynamic>;
      _name.text = user['name'] ?? '';
      _phone.text = user['phone'] ?? '';
      _location.text = user['location'] ?? '';

      // Load artisan profile for bio, craft, coords
      if (user['role'] == 'artisan') {
        final pRes = await _api.get('/artisans/map');
        final artisans = pRes.data['artisans'] as List;
        final me =
            artisans.firstWhereOrNull((a) => a['id'] == _authSvc.user?['id']);
        if (me != null) {
          _lat.text = me['latitude']?.toString() ?? '';
          _lng.text = me['longitude']?.toString() ?? '';
        }

        // Also get bio and craft from products endpoint profile
        //final prodRes = await _api.get('/products/my');
        // craft_type and bio come from artisan_profiles
        // We'll load them via a dedicated call if needed
      }
    } catch (_) {
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      // Update basic user info
      await _api.patch('/auth/profile', data: {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'location': _location.text.trim(),
        'bio': _bio.text.trim(),
        'craft_type': _craftType.text.trim(),
      });

      // Update auth service local data
      final user = Map<String, dynamic>.from(_authSvc.user ?? {});
      user['name'] = _name.text.trim();
      user['phone'] = _phone.text.trim();
      user['location'] = _location.text.trim();
      await _authSvc.saveSession(_authSvc.token!, user);

      Get.snackbar('تم الحفظ', 'تم تحديث ملفك الشخصي بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight,
          colorText: AppColors.primaryDark);
    } catch (e) {
      Get.snackbar('خطأ', _errMsg(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _savingProfile = false);
    }
  }

  Future<void> _saveLocation() async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) {
      Get.snackbar('خطأ', 'أدخل إحداثيات صحيحة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _savingLocation = true);
    try {
      await _api.patch('/artisans/location', data: {
        'latitude': lat,
        'longitude': lng,
      });
      Get.snackbar('تم التحديث', 'تم تحديث موقعك على الخريطة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight,
          colorText: AppColors.primaryDark);
    } catch (e) {
      Get.snackbar('خطأ', _errMsg(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _savingLocation = false);
    }
  }

  String _errMsg(dynamic e) {
    try {
      return e.response?.data['message'] ?? 'حدث خطأ';
    } catch (_) {
      return 'تعذر الاتصال';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    _buildSection('المعلومات الأساسية', Icons.person_outline),
                    const SizedBox(height: 12),
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
                      hint: 'تلمسان، وهران...',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _craftType,
                      label: 'نوع الحرفة',
                      hint: 'فخار، شموع، نسيج...',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _bio,
                      label: 'نبذة عنك',
                      hint: 'اكتب وصفاً مختصراً عن نفسك وحرفتك...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'حفظ المعلومات',
                      isLoading: _savingProfile,
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 28),

                    // ── Location section ──────────────────────────────
                    _buildSection('موقعك على الخريطة', Icons.map_outlined),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'يتيح تحديد موقعك للعملاء إيجادك على خريطة الحرفيين.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            height: 1.5),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('اختر مدينتك بسرعة:',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _buildCityPresets(),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: AppTextField(
                          controller: _lat,
                          label: 'خط العرض (Latitude)',
                          hint: '34.8828',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _lng,
                          label: 'خط الطول (Longitude)',
                          hint: '-1.3167',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'تحديث الموقع على الخريطة',
                      isLoading: _savingLocation,
                      onPressed: _saveLocation,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final name = _authSvc.user?['name'] ?? 'ح';
    return Center(
      child: Stack(
        children: [
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
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildCityPresets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cityPresets.map((city) {
        final isSelected = _location.text == city['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _location.text = city['name']!;
              _lat.text = city['lat']!;
              _lng.text = city['lng']!;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on,
                  size: 12,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(city['name']!,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
