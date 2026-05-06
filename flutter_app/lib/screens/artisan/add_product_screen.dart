import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import '../../core/services/api_service.dart';
import '../../controllers/product_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _title = TextEditingController();
  final _titleAr = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategory;
  File? _image;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final catCtrl = Get.find<ProductController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'إضافة منتج',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              _buildImagePicker(),
              const SizedBox(height: 20),
              AppTextField(
                controller: _titleAr,
                label: 'اسم المنتج (عربي)',
                hint: 'مثال: إبريق فخاري تقليدي',
                validator: (v) => v!.isEmpty ? 'أدخل اسم المنتج' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _title,
                label: 'Product name (English)',
                hint: 'e.g. Traditional pottery jug',
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _description,
                label: 'الوصف',
                hint: 'وصف المنتج...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _price,
                      label: 'السعر (دج)',
                      hint: '1200',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'أدخل السعر' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _stock,
                      label: 'المخزون',
                      hint: '10',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'أدخل الكمية' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCategoryDropdown(catCtrl),
              const SizedBox(height: 28),
              AppButton(
                label: 'نشر المنتج',
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اضغط لإضافة صورة',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'اختياري',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ProductController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفئة',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<int>(
            value: _selectedCategory,
            hint: const Text('اختر الفئة'),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: ctrl.categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon ?? ''} ${c.nameAr ?? c.name}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      final formData = dio.FormData.fromMap({
        'title': _title.text.trim().isEmpty
            ? _titleAr.text.trim()
            : _title.text.trim(),
        'title_ar': _titleAr.text.trim(),
        'description': _description.text.trim(),
        'price': _price.text.trim(),
        'stock': _stock.text.trim(),
        if (_selectedCategory != null) 'category_id': _selectedCategory,
        if (_image != null) 'image': await dio.MultipartFile.fromFile(_image!.path),
      });
      await api.postForm('/products', formData);
      Get.back();
      Get.snackbar(
        'تم النشر',
        'تم إضافة منتجك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      final msg = (e as dynamic).response?.data['message'] ?? 'حدث خطأ';
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _loading = false);
    }
  }
}
