import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naam_aya/widgets/upcoming_sessions_widget.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart' as auth_svc;
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../client/product_detail_screen.dart';
import '../client/cart_screen.dart';
import '../client/orders_screen.dart';
import '../client/learn_screen.dart';
import '../client/search_screen.dart';
import '../client/artisan_map_screen.dart';
import '../client/client_profile_screen.dart';
import '../client/favorites_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productCtrl = Get.find<ProductController>();
    final orderCtrl = Get.find<OrderController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(authCtrl, orderCtrl),
          _buildSearchBar(),
          _buildSortRow(productCtrl),
          _buildCategoryList(productCtrl),
// Replace the Expanded part with this:
          Expanded(
            child: Column(
              children: [
                const UpcomingSessionsWidget(),
                Expanded(
                  child: _buildProductGrid(productCtrl, orderCtrl),
                ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: _ClientBottomNav(orderCtrl: orderCtrl),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(AuthController authCtrl, OrderController orderCtrl) {
    final userName = Get.find<auth_svc.AuthService>().user?['name'] ?? '';
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      child: Row(
        children: [
          // Profile avatar tap
          GestureDetector(
            onTap: () => Get.to(() => const ClientProfileScreen()),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                userName.isNotEmpty ? userName[0] : 'ع',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مرحباً، $userName',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const Spacer(),
          // Favorites icon with count
          Obx(() {
            final favCtrl = Get.find<FavoritesController>();
            final count = favCtrl.favoriteIds.length;
            return Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () => Get.to(() => const FavoritesScreen()),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ]);
          }),
          // Cart icon with count
          Obx(() => Stack(clipBehavior: Clip.none, children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white),
                  onPressed: () => Get.to(() => const CartScreen()),
                ),
                if (orderCtrl.cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                      child: Text('${orderCtrl.cartCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ])),
        ],
      ),
    );
  }

  // ── Search bar — tappable ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: () => Get.to(() => const SearchScreen()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.search, color: Colors.white60, size: 20),
            SizedBox(width: 10),
            Text('ابحث عن منتج أو حرفي...',
                style: TextStyle(color: Colors.white60, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  // ── Sort chips ────────────────────────────────────────────────────────────
  Widget _buildSortRow(ProductController ctrl) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        const Text('ترتيب:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        Obx(() => _sortChip(ctrl, 'newest', 'الأحدث')),
        const SizedBox(width: 6),
        Obx(() => _sortChip(ctrl, 'rating', 'الأعلى تقييماً')),
        const SizedBox(width: 6),
        Obx(() => _sortChip(ctrl, 'popular', 'الأكثر طلباً')),
      ]),
    );
  }

  Widget _sortChip(ProductController ctrl, String value, String label) {
    final selected = ctrl.sortBy.value == value;
    return GestureDetector(
      onTap: () => ctrl.setSort(value),
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
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────
  Widget _buildCategoryList(ProductController ctrl) {
    return Container(
      color: AppColors.surface,
      height: 54,
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: ctrl.categories.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CategoryChip(
                    label: 'الكل',
                    icon: null,
                    selected: ctrl.selectedCategory.value == null,
                    onTap: () => ctrl.setCategory(null),
                  ),
                );
              }
              final cat = ctrl.categories[i - 1];
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CategoryChip(
                  label: cat.nameAr ?? cat.name,
                  icon: cat.icon,
                  selected: ctrl.selectedCategory.value == cat.id,
                  onTap: () => ctrl.setCategory(cat.id),
                ),
              );
            },
          )),
    );
  }

  // ── Product grid ──────────────────────────────────────────────────────────
  Widget _buildProductGrid(ProductController ctrl, OrderController orderCtrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (ctrl.products.isEmpty) {
        return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('لا توجد منتجات',
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ctrl.fetchProducts(refresh: true),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72),
          itemCount: ctrl.products.length,
          itemBuilder: (_, i) {
            final p = ctrl.products[i];
            return ProductCard(
              product: p,
              onTap: () => Get.to(() => ProductDetailScreen(productId: p.id)),
              onAddToCart: () => orderCtrl.addToCart(p),
            );
          },
        ),
      );
    });
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────
class _ClientBottomNav extends StatefulWidget {
  final OrderController orderCtrl;
  const _ClientBottomNav({required this.orderCtrl});

  @override
  State<_ClientBottomNav> createState() => _ClientBottomNavState();
}

class _ClientBottomNavState extends State<_ClientBottomNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) {
        setState(() => _index = i);
        if (i == 1) Get.to(() => const ArtisanMapScreen());
        if (i == 2) Get.to(() => const FavoritesScreen());
        if (i == 3) Get.to(() => const LearnScreen());
        if (i == 4) Get.to(() => const OrdersScreen());
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), label: 'الخريطة'),
        BottomNavigationBarItem(
          icon: Obx(() {
            final count = Get.find<FavoritesController>().favoriteIds.length;
            return Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.favorite_border),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ]);
          }),
          label: 'المحفوظات',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          label: 'جلسات',
        ),
        BottomNavigationBarItem(
          icon: Obx(() => Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.receipt_long_outlined),
                if (widget.orderCtrl.orders.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ])),
          label: 'طلباتي',
        ),
      ],
    );
  }
}
