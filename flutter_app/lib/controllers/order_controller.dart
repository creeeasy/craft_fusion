import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../core/constants/app_constants.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;
}

class OrderController extends GetxController {
  final _api = Get.find<ApiService>();

  final cartItems = <CartItem>[].obs;
  final orders = <Order>[].obs;
  final isLoading = false.obs;

  double get cartTotal => cartItems.fold(0, (s, i) => s + i.subtotal);
  int get cartCount => cartItems.fold(0, (s, i) => s + i.quantity);

  void addToCart(Product product) {
    final existing =
        cartItems.firstWhereOrNull((i) => i.product.id == product.id);
    if (existing != null) {
      existing.quantity++;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(product: product));
    }
    Get.snackbar(
        'تمت الإضافة', '${product.titleAr ?? product.title} أضيف للسلة',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  void removeFromCart(int productId) {
    cartItems.removeWhere((i) => i.product.id == productId);
  }

  void updateQty(int productId, int qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    final item = cartItems.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) {
      item.quantity = qty;
      cartItems.refresh();
    }
  }

  Future<bool> placeOrder(int productId, int quantity) async {
    isLoading.value = true;
    try {
      await _api.post('/orders',
          data: {'product_id': productId, 'quantity': quantity});
      return true;
    } catch (e) {
      Get.snackbar('خطأ', _extractError(e),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> placeCartOrders() async {
    isLoading.value = true;
    int success = 0;
    for (final item in cartItems.toList()) {
      final ok = await placeOrder(item.product.id, item.quantity);
      if (ok) success++;
    }
    isLoading.value = false;
    if (success > 0) {
      cartItems.clear();
      Get.snackbar('تم الطلب', 'تم تقديم $success طلب بنجاح',
          snackPosition: SnackPosition.BOTTOM);
      Get.offAllNamed(AppRoutes.orders);
    }
  }

  Future<void> fetchMyOrders() async {
    isLoading.value = true;
    try {
      final res = await _api.get('/orders/my');
      orders.value =
          (res.data['orders'] as List).map((e) => Order.fromJson(e)).toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitReview(int orderId, int rating, String comment) async {
    try {
      await _api.post('/orders/$orderId/review',
          data: {'rating': rating, 'comment': comment});
      Get.snackbar('شكراً', 'تم إرسال تقييمك',
          snackPosition: SnackPosition.BOTTOM);
      fetchMyOrders();
    } catch (e) {
      Get.snackbar('خطأ', _extractError(e),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      if (status == 'cancelled') {
        await _api.post('/orders/$orderId/cancel');
      } else {
        await _api.patch('/orders/$orderId/status', data: {'status': status});
      }
      fetchMyOrders();
      Get.snackbar('تم', 'تم تحديث حالة الطلب',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('خطأ', _extractError(e),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _extractError(dynamic e) {
    try {
      return e.response?.data['message'] ?? 'حدث خطأ';
    } catch (_) {
      return 'تعذر الاتصال';
    }
  }
}
