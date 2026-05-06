import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final _api = Get.find<ApiService>();

  final products = <Product>[].obs;
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<int>();
  final sortBy = 'newest'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final selectedProduct = Rxn<Product>();
  final productReviews = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _api.get('/products/categories');
      categories.value = (res.data['categories'] as List)
          .map((e) => Category.fromJson(e))
          .toList();
    } catch (_) {}
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    isLoading.value = true;
    try {
      final params = <String, dynamic>{};
      if (selectedCategory.value != null)
        params['category'] = selectedCategory.value;
      if (sortBy.value != 'newest') params['sort'] = sortBy.value;
      if (searchQuery.value.isNotEmpty) params['search'] = searchQuery.value;

      final res = await _api.get('/products', params: params);
      products.value = (res.data['products'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProductDetail(int id) async {
    selectedProduct.value = null; // clear old data first
    productReviews.clear();
    isLoading.value = true;
    try {
      final res = await _api.get('/products/$id');
      selectedProduct.value = Product.fromJson(res.data['product']);
      productReviews.value =
          List<Map<String, dynamic>>.from(res.data['reviews'] ?? []);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void setCategory(int? categoryId) {
    selectedCategory.value = categoryId;
    fetchProducts();
  }

  void setSort(String sort) {
    sortBy.value = sort;
    fetchProducts();
  }

  void setSearch(String query) {
    searchQuery.value = query;
    fetchProducts();
  }
}
