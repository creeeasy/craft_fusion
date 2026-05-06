import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../controllers/order_controller.dart';
import 'product_detail_screen.dart';

class ArtisanProfileScreen extends StatefulWidget {
  final int artisanId;
  final String artisanName;
  const ArtisanProfileScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  final _api = Get.find<ApiService>();
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      // Load all products filtered by artisan
      final res =
          await _api.get('/products', params: {'artisan': widget.artisanId});
      final allProducts = (res.data['products'] as List)
          .map((e) => Product.fromJson(e))
          .toList();

      // Extract profile from first product
      if (allProducts.isNotEmpty) {
        final p = allProducts.first;
        _profile = {
          'name': p.artisanName,
          'location': p.location,
          'badge': p.badge,
          'avg_rating': p.avgRating,
          'is_sponsored': p.isSponsored,
          'total_sales': allProducts.fold(0, (s, pr) => s + pr.totalOrders),
        };
      }

      // Load reviews via dedicated endpoint (single request, no N+1)
      final revRes = await _api.get('/artisans/${widget.artisanId}/reviews');
      final allReviews =
          List<Map<String, dynamic>>.from(revRes.data['reviews'] ?? []);

      setState(() {
        _products = allProducts;
        _reviews = allReviews;
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStats(),
                        const SizedBox(height: 20),
                        _buildProductsSection(),
                        const SizedBox(height: 20),
                        _buildReviewsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final badge = _profile?['badge'] ?? 'new';
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white24,
                child: Text(
                  (widget.artisanName)[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.artisanName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_profile?['location'] != null) ...[
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      _profile!['location'],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _buildBadgeChip(badge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String badge) {
    final isGold = badge == 'gold';
    final isSilver = badge == 'silver';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isGold
            ? AppColors.accentLight
            : isSilver
                ? Colors.grey.shade100
                : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 12,
            color: isGold
                ? AppColors.gold
                : isSilver
                    ? AppColors.silver
                    : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isGold
                ? 'ذهبي'
                : isSilver
                    ? 'فضي'
                    : 'جديد',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isGold
                  ? AppColors.gold
                  : isSilver
                      ? AppColors.silver
                      : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final rating = (_profile?['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final sales = _profile?['total_sales'] ?? 0;
    return Row(
      children: [
        _statBox(
          icon: Icons.star,
          iconColor: AppColors.accent,
          value: rating.toStringAsFixed(1),
          label: 'التقييم',
        ),
        const SizedBox(width: 10),
        _statBox(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.primary,
          value: '${_products.length}',
          label: 'المنتجات',
        ),
        const SizedBox(width: 10),
        _statBox(
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.primaryDark,
          value: '$sales',
          label: 'المبيعات',
        ),
        const SizedBox(width: 10),
        _statBox(
          icon: Icons.rate_review_outlined,
          iconColor: Colors.purple,
          value: '${_reviews.length}',
          label: 'التقييمات',
        ),
      ],
    );
  }

  Widget _statBox({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: iconColor,
              ),
            ),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المنتجات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_products.isEmpty)
          const Text(
            'لا توجد منتجات بعد',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _products.length,
            itemBuilder: (_, i) {
              final p = _products[i];
              return GestureDetector(
                onTap: () => Get.to(() => ProductDetailScreen(productId: p.id)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11)),
                        child: p.image != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    '${AppStrings.baseUrl.replaceAll('/api', '')}${p.image}',
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _imgPlaceholder(p.icon),
                              )
                            : _imgPlaceholder(p.icon),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.titleAr ?? p.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    '${p.price.toStringAsFixed(0)} دج',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Get.find<OrderController>()
                                        .addToCart(p),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'آراء العملاء',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_profile?['avg_rating'] != null)
              Row(
                children: [
                  RatingBarIndicator(
                    rating: (_profile!['avg_rating'] as num).toDouble(),
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: AppColors.accent),
                    itemCount: 5,
                    itemSize: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (_profile!['avg_rating'] as num).toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          const Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ..._reviews.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (r['client_name'] ?? 'ع')[0],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r['client_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      RatingBarIndicator(
                        rating: (r['rating'] as num).toDouble(),
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: AppColors.accent),
                        itemCount: 5,
                        itemSize: 13,
                      ),
                    ],
                  ),
                  if (r['product_title'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      r['product_title'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                  if (r['comment'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      r['comment'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imgPlaceholder(String? icon) => Container(
        height: 110,
        color: AppColors.primaryLight,
        child: Center(
          child: Text(icon ?? '🏺', style: const TextStyle(fontSize: 40)),
        ),
      );
}
