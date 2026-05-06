import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});
  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _api = Get.find<ApiService>();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/products/my');
      setState(() {
        _products = (res.data['products'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('منتجاتي',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 28),
            onPressed: () =>
                Get.to(() => const AddProductScreen())?.then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _products.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 72, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text('لا توجد منتجات بعد',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('أضف منتجك الأول'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                        onPressed: () => Get.to(() => const AddProductScreen())
                            ?.then((_) => _load()),
                      ),
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (_, i) => _ProductTile(
                      product: _products[i],
                      onEdit: () =>
                          Get.to(() => EditProductScreen(product: _products[i]))
                              ?.then((updated) {
                        if (updated == true) _load();
                      }),
                    ),
                  ),
                ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  const _ProductTile({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: product.isActive
                ? AppColors.border
                : AppColors.border.withOpacity(0.4)),
      ),
      child: Row(children: [
        Opacity(
          opacity: product.isActive ? 1.0 : 0.45,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(product.icon ?? '🏺',
                    style: const TextStyle(fontSize: 26))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: product.isActive ? 1.0 : 0.55,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.titleAr ?? product.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 3),
              Row(children: [
                Text('${product.price.toStringAsFixed(0)} دج',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text('مخزون: ${product.stock}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
              Text('${product.totalOrders} طلب',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: product.isActive
                  ? AppColors.primaryLight
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(product.isActive ? 'نشط' : 'متوقف',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: product.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary)),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined,
                    size: 13, color: AppColors.textSecondary),
                SizedBox(width: 3),
                Text('تعديل',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}
