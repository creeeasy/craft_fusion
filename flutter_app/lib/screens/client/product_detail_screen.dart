import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_constants.dart';
import 'artisan_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ProductController>().fetchProductDetail(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductController>();
    final orderCtrl = Get.find<OrderController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (ctrl.isLoading.value || ctrl.selectedProduct.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final p = ctrl.selectedProduct.value!;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  p.image != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${AppStrings.baseUrl.replaceAll('/api', '')}${p.image}',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _placeholderImage(p.icon ?? '🏺'),
                        )
                      : _placeholderImage(p.icon ?? '🏺'),
                  if (p.isSponsored)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('مدفوع الترويج',
                            style: TextStyle(
                                color: AppColors.sponsored,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadgeRow(p),
                      const SizedBox(height: 8),
                      Text(p.titleAr ?? p.title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                          textDirection: TextDirection.rtl),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('${p.price.toStringAsFixed(0)} دج',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const Spacer(),
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${p.stock} متبقي',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 16),
                      _buildArtisanCard(p),
                      if (p.description != null) ...[
                        const SizedBox(height: 16),
                        const Text('الوصف',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(p.description!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, height: 1.5),
                            textDirection: TextDirection.rtl),
                      ],
                      const SizedBox(height: 20),
                      _buildQtySelector(),
                      const SizedBox(height: 16),
                      _buildReviews(ctrl),
                      const SizedBox(height: 80),
                    ]),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final p = ctrl.selectedProduct.value;
        if (p == null) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4))
            ],
          ),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('أضف للسلة'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: p.stock > 0 ? () => orderCtrl.addToCart(p) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: p.stock > 0
                    ? () async {
                        final ok = await orderCtrl.placeOrder(p.id, _qty);
                        if (ok) {
                          // Show success dialog
                          await Get.dialog(
                            AlertDialog(
                              title: const Text('✅ تم الطلب بنجاح'),
                              content: const Text(
                                  'سيتم التواصل معك قريباً لتأكيد الطلب'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back(); // Close dialog
                                    Get.back(); // Close product screen
                                  },
                                  child: const Text('حسناً'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    : null,
                child: Obx(() => orderCtrl.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('اطلب الآن')),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildBadgeRow(p) {
    return Row(children: [
      if (p.badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: p.badge == 'gold'
                ? AppColors.accentLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: p.badge == 'gold' ? AppColors.gold : AppColors.border),
          ),
          child: Row(children: [
            Icon(Icons.star,
                size: 12,
                color: p.badge == 'gold' ? AppColors.gold : AppColors.silver),
            const SizedBox(width: 4),
            Text(
                p.badge == 'gold'
                    ? 'ذهبي'
                    : p.badge == 'silver'
                        ? 'فضي'
                        : 'جديد',
                style: TextStyle(
                    fontSize: 11,
                    color:
                        p.badge == 'gold' ? AppColors.gold : AppColors.silver,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      const SizedBox(width: 8),
      RatingBarIndicator(
        rating: p.avgRating,
        itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.accent),
        itemCount: 5,
        itemSize: 16,
      ),
      const SizedBox(width: 4),
      Text(p.avgRating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildArtisanCard(p) {
    return GestureDetector(
      onTap: () => Get.to(() => ArtisanProfileScreen(
            artisanId: p.artisanId,
            artisanName: p.artisanName ?? '',
          )),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text((p.artisanName ?? 'ح')[0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.artisanName ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            if (p.location != null)
              Row(children: [
                const Icon(Icons.location_on,
                    size: 12, color: AppColors.primary),
                Text(p.location!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ]),
          ]),
          const Spacer(),
          Text('${p.totalOrders} مبيعة',
              style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _buildQtySelector() {
    return Row(children: [
      const Text('الكمية:', style: TextStyle(fontWeight: FontWeight.bold)),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
        onPressed: () {
          if (_qty > 1) setState(() => _qty--);
        },
      ),
      Text('$_qty',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: () => setState(() => _qty++),
      ),
    ]);
  }

  Widget _buildReviews(ProductController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('التقييمات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      Obx(() => ctrl.productReviews.isEmpty
          ? const Text('لا توجد تقييمات بعد',
              style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: ctrl.productReviews
                  .map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(r['client_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const Spacer(),
                                RatingBarIndicator(
                                    rating: (r['rating'] as num).toDouble(),
                                    itemBuilder: (_, __) => const Icon(
                                        Icons.star,
                                        color: AppColors.accent),
                                    itemCount: 5,
                                    itemSize: 14),
                              ]),
                              if (r['comment'] != null) ...[
                                const SizedBox(height: 6),
                                Text(r['comment'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                    textDirection: TextDirection.rtl),
                              ],
                            ]),
                      ))
                  .toList(),
            )),
    ]);
  }

  Widget _placeholderImage(String emoji) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 80))),
    );
  }
}
