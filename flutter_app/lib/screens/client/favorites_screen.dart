import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/constants/app_constants.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _ctrl = Get.find<FavoritesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المحفوظات',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (_ctrl.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border,
                    size: 80, color: AppColors.textHint.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text('لا توجد منتجات محفوظة',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('اضغط ♡ على أي منتج لحفظه هنا',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.loadFavorites,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ctrl.favorites.length,
            itemBuilder: (_, i) {
              final p = _ctrl.favorites[i];
              return GestureDetector(
                onTap: () => Get.to(() => ProductDetailScreen(productId: p.id)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(13)),
                      child: p.image != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  '${AppStrings.baseUrl.replaceAll('/api', '')}${p.image}',
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _placeholder(p.icon),
                            )
                          : _placeholder(p.icon),
                    ),
                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.titleAr ?? p.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl),
                            const SizedBox(height: 4),
                            Text(p.artisanName ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text('${p.price.toStringAsFixed(0)} دج',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    // Remove button
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _ctrl.toggle(p.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite,
                              color: AppColors.error, size: 18),
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _placeholder(String? icon) => Container(
        width: 90,
        height: 90,
        color: AppColors.primaryLight,
        child: Center(
            child: Text(icon ?? '🏺', style: const TextStyle(fontSize: 32))),
      );
}
