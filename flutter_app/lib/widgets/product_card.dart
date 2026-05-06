import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../controllers/favorites_controller.dart';
import '../core/services/auth_service.dart' as auth_svc;

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isClient = Get.find<auth_svc.AuthService>().role == 'client';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: product.isSponsored ? AppColors.accent : AppColors.border,
            width: product.isSponsored ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: product.image != null
                  ? CachedNetworkImage(
                      imageUrl:
                          '${AppStrings.baseUrl.replaceAll('/api', '')}${product.image}',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Sponsored badge
            if (product.isSponsored)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ممول',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.sponsored,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            // Quality badge
            if (product.badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: product.badge == 'gold'
                        ? AppColors.accentLight
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.badge == 'gold'
                        ? '★ ذهبي'
                        : product.badge == 'silver'
                            ? '◆ فضي'
                            : '✦ جديد',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.badge == 'gold'
                            ? AppColors.gold
                            : AppColors.silver),
                  ),
                ),
              ),
            // Favorite heart (clients only)
            if (isClient)
              Positioned(
                bottom: 8,
                right: 8,
                child: _FavoriteButton(productId: product.id),
              ),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.titleAr ?? product.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 3),
                    if (product.avgRating > 0)
                      RatingBarIndicator(
                        rating: product.avgRating,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: AppColors.accent),
                        itemCount: 5,
                        itemSize: 12,
                      ),
                    const Spacer(),
                    Row(children: [
                      Text('${product.price.toStringAsFixed(0)} دج',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_shopping_cart,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 130,
        color: AppColors.primaryLight,
        child: Center(
            child: Text(product.icon ?? '🏺',
                style: const TextStyle(fontSize: 48))),
      );
}

// Safe favorite button — only renders if FavoritesController is registered
class _FavoriteButton extends StatelessWidget {
  final int productId;
  const _FavoriteButton({required this.productId});

  @override
  Widget build(BuildContext context) {
    try {
      final ctrl = Get.find<FavoritesController>();
      return Obx(() {
        final saved = ctrl.isFavorite(productId);
        return GestureDetector(
          onTap: () => ctrl.toggle(productId),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              color: saved ? AppColors.error : AppColors.textHint,
              size: 16,
            ),
          ),
        );
      });
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
