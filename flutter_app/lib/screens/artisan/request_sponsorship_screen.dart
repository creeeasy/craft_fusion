import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RequestSponsorshipScreen extends StatefulWidget {
  const RequestSponsorshipScreen({super.key});
  @override
  State<RequestSponsorshipScreen> createState() =>
      _RequestSponsorshipScreenState();
}

class _RequestSponsorshipScreenState extends State<RequestSponsorshipScreen> {
  final _api = Get.find<ApiService>();
  final _promoTitle = TextEditingController();
  final _promoMessage = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _package = 'bronze';
  bool _loading = false;
  List<File> _photos = [];

  final _packages = [
    {
      'key': 'bronze',
      'label': 'برونزي',
      'days': '7 أيام',
      'price': '1,000 دج',
      'perks': 'ظهور في نتائج البحث',
      'color': const Color(0xFF795548),
      'bgColor': const Color(0xFFF5F0EE),
    },
    {
      'key': 'silver',
      'label': 'فضي',
      'days': '14 يوم',
      'price': '2,500 دج',
      'perks': 'بحث + بانر الفئة',
      'color': AppColors.silver,
      'bgColor': const Color(0xFFF1EFE8),
    },
    {
      'key': 'gold',
      'label': 'ذهبي',
      'days': '30 يوم',
      'price': '5,000 دج',
      'perks': 'بانر الرئيسية + بحث + فئة',
      'color': AppColors.gold,
      'bgColor': AppColors.accentLight,
    },
  ];

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) {
      Get.snackbar('الحد الأقصى', 'يمكنك إضافة 3 صور كحد أقصى',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      Get.snackbar('صور مطلوبة', 'أضف صورة واحدة على الأقل لمنتجاتك',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _loading = true);
    try {
      final formData = FormData.fromMap({
        'package': _package,
        'promo_title': _promoTitle.text.trim(),
        'promo_message': _promoMessage.text.trim(),
        for (int i = 0; i < _photos.length; i++)
          'photos': await MultipartFile.fromFile(_photos[i].path),
      });

      // Dio doesn't support repeated keys well — use list
      final fields = <MapEntry<String, dynamic>>[
        MapEntry('package', _package),
        MapEntry('promo_title', _promoTitle.text.trim()),
        MapEntry('promo_message', _promoMessage.text.trim()),
      ];
      final photoFiles = await Future.wait(
        _photos.map((f) => MultipartFile.fromFile(f.path)),
      );
      final fd = FormData();
      for (final e in fields)
        fd.fields.add(MapEntry(e.key, e.value.toString()));
      for (final pf in photoFiles) fd.files.add(MapEntry('photos', pf));

      await _api.postForm('/sponsorships/request', fd);
      Get.back();
      Get.snackbar(
        'تم الإرسال ✓',
        'طلب الترويج قيد المراجعة — سيتم الرد خلال 24 ساعة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryLight,
        colorText: AppColors.primaryDark,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      final msg = (e as dynamic).response?.data['message'] ?? 'حدث خطأ';
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طلب ترويج مدفوع',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),
              _buildPackageSelector(),
              const SizedBox(height: 20),
              _buildPhotoSection(),
              const SizedBox(height: 20),
              _buildPromoFields(),
              const SizedBox(height: 28),
              AppButton(
                label: 'إرسال طلب الترويج',
                isLoading: _loading,
                onPressed: _submit,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              const Text(
                'سيراجع الإداري محتوى الإعلان قبل نشره. قد يُرفض الطلب إذا لم يكن المحتوى مناسباً.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: const Row(children: [
        Icon(Icons.star, color: AppColors.gold, size: 28),
        SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('روّج لحرفتك',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.sponsored)),
            SizedBox(height: 3),
            Text('اعرض صور أعمالك في أبرز أماكن التطبيق وجذب عملاء أكثر',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textDirection: TextDirection.rtl),
          ]),
        ),
      ]),
    );
  }

  // ── Package selector ──────────────────────────────────────────────────────
  Widget _buildPackageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر الباقة',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ..._packages.map((pkg) {
          final selected = _package == pkg['key'];
          final color = pkg['color'] as Color;
          final bgColor = pkg['bgColor'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _package = pkg['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? bgColor : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 2 : 1),
              ),
              child: Row(children: [
                // Radio dot
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? color : AppColors.border, width: 2),
                    color: selected ? color : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(pkg['label'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: color)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(pkg['days'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(pkg['perks'] as String,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                ),
                Text(pkg['price'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── Photo picker ──────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('صور الإعلان',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Text('(${_photos.length}/3)',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          const Text('مطلوبة على الأقل 1',
              style: TextStyle(fontSize: 11, color: AppColors.error)),
        ]),
        const SizedBox(height: 4),
        const Text('اختر صوراً واضحة تعكس جودة حرفتك',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: Row(
            children: [
              // Existing photos
              ..._photos.asMap().entries.map((entry) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(entry.value, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(entry.key),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )),
              // Add photo button
              if (_photos.length < 3)
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary,
                          style: BorderStyle.solid,
                          width: 1.5),
                    ),
                    child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primary, size: 28),
                          SizedBox(height: 4),
                          Text('إضافة صورة',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Promo text fields ─────────────────────────────────────────────────────
  Widget _buildPromoFields() {
    return Column(children: [
      AppTextField(
        controller: _promoTitle,
        label: 'عنوان الإعلان',
        hint: 'مثال: أفضل فخار أصيل في تلمسان',
        validator: (v) => v!.isEmpty ? 'أدخل عنوان الإعلان' : null,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _promoMessage,
        label: 'رسالة قصيرة للعملاء (اختياري)',
        hint: 'اكتب سبباً يجعل العملاء يختارونك...',
        maxLines: 3,
      ),
    ]);
  }
}
