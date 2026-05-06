import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = Get.find<ProductController>();
  final _orderCtrl = Get.find<OrderController>();
  final _searchController = TextEditingController();
  String _sort = 'newest';
  int? _selectedCategory;
  String _priceFilter = 'all';

  final _priceRanges = {
    'all': {'label': 'الكل', 'min': 0, 'max': 999999},
    'low': {'label': 'أقل من 500', 'min': 0, 'max': 500},
    'mid': {'label': '500 – 2000', 'min': 500, 'max': 2000},
    'high': {'label': 'أكثر من 2000', 'min': 2000, 'max': 999999},
  };

  @override
  void initState() {
    super.initState();
    _ctrl.fetchCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    _ctrl.setSearch(_searchController.text.trim());
    _ctrl.selectedCategory.value = _selectedCategory;
    _ctrl.setSort(_sort);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ابحث عن منتج أو حرفي...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: (v) => _search(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _search();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildResultsHeader(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('ترتيب: ',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                _sortChip('newest', 'الأحدث'),
                const SizedBox(width: 6),
                _sortChip('rating', '★ الأعلى تقييماً'),
                const SizedBox(width: 6),
                _sortChip('popular', '🔥 الأكثر طلباً'),
                const SizedBox(width: 6),
                _sortChip('price_asc', 'السعر ↑'),
                const SizedBox(width: 6),
                _sortChip('price_desc', 'السعر ↓'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category row
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _catChip(null, 'الكل', null),
                    ..._ctrl.categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _catChip(c.id, c.nameAr ?? c.name, c.icon),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // Price range
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _priceRanges.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _priceChip(e.key, e.value['label'] as String),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sort = value);
        _search();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _catChip(int? id, String label, String? icon) {
    final selected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
        _search();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ]),
      ),
    );
  }

  Widget _priceChip(String key, String label) {
    final selected = _priceFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _priceFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? AppColors.sponsored : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text(
              '${_filteredProducts.length} نتيجة',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('لـ "${_searchController.text}"',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ]),
        ));
  }

  List get _filteredProducts {
    final range = _priceRanges[_priceFilter]!;
    final min = range['min'] as int;
    final max = range['max'] as int;
    return _ctrl.products
        .where((p) => p.price >= min && p.price <= max)
        .toList();
  }

  Widget _buildResults() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      final products = _filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 72, color: AppColors.textHint),
              const SizedBox(height: 12),
              const Text('لا توجد نتائج',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? 'جرب كلمات بحث مختلفة'
                    : 'جرب تغيير الفلاتر',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          return ProductCard(
            product: p,
            onTap: () => Get.to(() => ProductDetailScreen(productId: p.id)),
            onAddToCart: () => _orderCtrl.addToCart(p),
          );
        },
      );
    });
  }
}
