import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart' as auth_svc;
import '../models/product_model.dart';

class FavoritesController extends GetxController {
  final _api = Get.find<ApiService>();

  final favorites = <Product>[].obs;
  final favoriteIds = <int>{}.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load for clients
    if (Get.find<auth_svc.AuthService>().role == 'client') {
      loadIds();
    }
  }

  // Load just IDs (fast, called on startup)
  Future<void> loadIds() async {
    try {
      final res = await _api.get('/favorites/ids');
      favoriteIds.value =
          Set<int>.from((res.data['ids'] as List).map((id) => id as int));
    } catch (_) {}
  }

  // Load full product list (for wishlist screen)
  Future<void> loadFavorites() async {
    isLoading.value = true;
    try {
      final res = await _api.get('/favorites');
      favorites.value = (res.data['favorites'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  Future<void> toggle(int productId) async {
    // Optimistic update
    if (favoriteIds.contains(productId)) {
      favoriteIds.remove(productId);
      favorites.removeWhere((p) => p.id == productId);
    } else {
      favoriteIds.add(productId);
    }
    try {
      await _api.post('/favorites/$productId');
    } catch (_) {
      // Revert on error
      loadIds();
    }
  }
}
