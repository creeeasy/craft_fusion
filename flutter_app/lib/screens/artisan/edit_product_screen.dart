import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../controllers/product_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _api = Get.find<ApiService>();
  late final _title = TextEditingController(
      text: widget.product.titleAr ?? widget.product.title);
  late final _titleEn = TextEditingController(text: widget.product.title);
  late final _description =
      TextEditingController(text: widget.product.description ?? '');
  late final _price =
      TextEditingController(text: widget.product.price.toStringAsFixed(0));
  late final _stock =
      TextEditingController(text: widget.product.stock.toString());
  final _formKey = GlobalKey<FormState>();
  int? _categoryId;
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product.categoryName != null
        ? Get.find<ProductController>()
            .categories
            .firstWhereOrNull((c) => c.name == widget.product.categoryName)
            ?.id
        : null;
    _isActive = widget.product.isActive;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.put('/products/${widget.product.id}', data: {
        'title': _titleEn.text.trim().isEmpty
            ? _title.text.trim()
            : _titleEn.text.trim(),
        'title_ar': _title.text.trim(),
        'description': _description.text.trim(),
        'price': double.parse(_price.text.trim()),
        'stock': int.parse(_stock.text.trim()),
        'category_id': _categoryId,
        'is_active': _isActive ? 1 : 0,
      });
      Get.back(result: true);
      Get.snackbar('تم الحفظ', 'تم تحديث المنتج بنجاح',
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
    final catCtrl = Get.find<ProductController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تعديل المنتج',
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Product preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(widget.product.icon ?? '🏺',
                          style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.product.totalOrders} طلب مكتمل',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primaryDark)),
                  Text(
                      'تعديل: ${widget.product.titleAr ?? widget.product.title}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          fontSize: 13),
                      textDirection: TextDirection.rtl),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            AppTextField(
                controller: _title,
                label: 'اسم المنتج (عربي)',
                hint: 'إبريق فخاري تقليدي',
                validator: (v) => v!.isEmpty ? 'أدخل اسم المنتج' : null),
            const SizedBox(height: 12),
            AppTextField(
                controller: _titleEn,
                label: 'Product name (English)',
                hint: 'Traditional pottery jug'),
            const SizedBox(height: 12),
            AppTextField(
                controller: _description,
                label: 'الوصف',
                hint: 'وصف المنتج...',
                maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: AppTextField(
                      controller: _price,
                      label: 'السعر (دج)',
                      hint: '1200',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'أدخل السعر' : null)),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(
                      controller: _stock,
                      label: 'المخزون',
                      hint: '10',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'أدخل الكمية' : null)),
            ]),
            const SizedBox(height: 12),

            // Category
            const Text('الفئة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Obx(() => DropdownButtonFormField<int>(
                  value: _categoryId,
                  hint: const Text('اختر الفئة'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: catCtrl.categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child:
                                Text('${c.icon ?? ''} ${c.nameAr ?? c.name}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                )),
            const SizedBox(height: 16),

            // Active toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('حالة المنتج',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('إيقاف المنتج يخفيه من قائمة المنتجات',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                Switch(
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            AppButton(
                label: 'حفظ التعديلات', isLoading: _loading, onPressed: _save),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
