import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _api = Get.find<ApiService>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  int _duration = 60;
  int _maxPeople = 5;
  DateTime? _scheduledAt;
  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  String? _selectedImagePath;
  dio.MultipartFile? _imageFile;

  final _durations = [30, 60, 90, 120];
  final _maxOptions = [3, 5, 8, 10, 15];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _api.get('/products/categories');
      setState(() {
        _categories = res.data['categories'] ?? [];
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = await Get.bottomSheet<Widget>(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختر من المعرض'),
              onTap: () => Get.back(result: 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () => Get.back(result: 'camera'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );

    // For MVP, just show a placeholder since image picker needs extra setup
    if (picker != null) {
      setState(() {
        _selectedImagePath = 'placeholder';
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      Get.snackbar('خطأ', 'اختر تاريخ ووقت الجلسة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _loading = true);

    try {
      final formData = dio.FormData.fromMap({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'price': double.parse(_price.text.trim()),
        'duration_minutes': _duration,
        'max_participants': _maxPeople,
        'scheduled_at': _scheduledAt!.toIso8601String(),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        // For MVP, image upload optional
      });

      await _api.postForm('/sessions', formData);
      Get.back();
      Get.snackbar(
        'تم الإنشاء',
        'تمت إضافة الجلسة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryLight,
        colorText: AppColors.primaryDark,
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
        title: const Text('إضافة جلسة تعليمية',
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
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.school_outlined,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أنشئ جلسة تعليمية وشارك خبرتك مع الراغبين في تعلم حرفتك.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          height: 1.5),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Image picker (optional)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedImagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 32, color: AppColors.textHint),
                            SizedBox(height: 8),
                            Text('أضف صورة للجلسة (اختياري)',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              child: const Center(
                                  child: Icon(Icons.image,
                                      size: 40, color: AppColors.primary)),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                  onPressed: () =>
                                      setState(() => _selectedImagePath = null),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _title,
                label: 'عنوان الجلسة',
                hint: 'مثال: تعلم أساسيات صناعة الفخار',
                validator: (v) => v!.isEmpty ? 'أدخل عنوان الجلسة' : null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _description,
                label: 'الوصف',
                hint: 'ماذا سيتعلم المشاركون في هذه الجلسة؟',
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _price,
                label: 'السعر (دج)',
                hint: '300',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'أدخل سعر الجلسة' : null,
              ),
              const SizedBox(height: 20),

              // Category picker
              _sectionLabel('التصنيف'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: const Text('اختر التصنيف (اختياري)'),
                    value: _selectedCategoryId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('بدون تصنيف')),
                      ..._categories.map((cat) => DropdownMenuItem(
                            value: cat['id'],
                            child: Row(
                              children: [
                                Text(cat['icon'] ?? '📦'),
                                const SizedBox(width: 8),
                                Text(cat['name'] ?? ''),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Duration picker
              _sectionLabel('مدة الجلسة'),
              const SizedBox(height: 8),
              Row(
                children: _durations.map((d) {
                  final selected = _duration == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _duration = d),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Column(children: [
                          Text('$d',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          Text('دقيقة',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Max participants
              _sectionLabel('عدد المشاركين'),
              const SizedBox(height: 8),
              Row(
                children: _maxOptions.map((n) {
                  final selected = _maxPeople == n;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _maxPeople = n),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primaryDark
                                  : AppColors.border),
                        ),
                        child: Text('$n',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date & time picker
              _sectionLabel('التاريخ والوقت'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _scheduledAt != null
                            ? AppColors.primary
                            : AppColors.border,
                        width: _scheduledAt != null ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today,
                        color: _scheduledAt != null
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _scheduledAt != null
                          ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}  ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                          : 'اضغط لاختيار التاريخ والوقت',
                      style: TextStyle(
                          color: _scheduledAt != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              AppButton(
                label: 'نشر الجلسة',
                isLoading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));
}
