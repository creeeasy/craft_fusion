import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _api = Get.find<ApiService>();
  List<dynamic> _products = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/products',
          params: _search.isNotEmpty ? {'search': _search} : null);
      setState(() {
        _products = res.data['products'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleProduct(int id, bool currentActive) async {
    try {
      await _api.patch('/admin/products/$id/toggle',
          data: {'is_active': currentActive ? 0 : 1});
      _load();
      Get.snackbar(
        currentActive ? 'تم الإيقاف' : 'تم التفعيل',
        currentActive ? 'تم إيقاف المنتج' : 'تم تفعيل المنتج',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المنتجات',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) {
              _search = v;
              if (v.isEmpty || v.length > 2) _load();
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _products.isEmpty
                  ? const Center(
                      child: Text('لا توجد منتجات',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _products.length,
                        itemBuilder: (_, i) {
                          final p = _products[i];
                          final active = (p['is_active'] ?? 1) == 1;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                    child: Text(p['icon'] ?? '🏺',
                                        style: const TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['title_ar'] ?? p['title'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                      textDirection: TextDirection.rtl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(p['artisan_name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                                  Text(
                                      '${double.tryParse(p['price'].toString())?.toStringAsFixed(0)} دج  •  ${p['total_orders']} طلب',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                ],
                              )),
                              Switch(
                                value: active,
                                activeColor: AppColors.primary,
                                onChanged: (_) =>
                                    _toggleProduct(p['id'], active),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
