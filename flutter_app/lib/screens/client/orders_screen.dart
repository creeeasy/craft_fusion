import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<OrderController>().fetchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طلباتي',
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
        if (ctrl.isLoading.value)
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        if (ctrl.orders.isEmpty) {
          return const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined,
                  size: 72, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('لا توجد طلبات بعد',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.orders.length,
          itemBuilder: (_, i) => _OrderCard(order: ctrl.orders[i], ctrl: ctrl),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final OrderController ctrl;
  const _OrderCard({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(order.productTitle ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textDirection: TextDirection.rtl),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(order.statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.store_outlined,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(order.artisanName ?? '',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const Spacer(),
          Text('${order.totalPrice.toStringAsFixed(0)} دج',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 4),
        Text('الكمية: ${order.quantity}',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        const Divider(height: 16),
        GestureDetector(
          onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
          child: Row(children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            const Text('تتبع الطلب',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
          ]),
        ),
        if (order.status == 'pending') ...[
          const Divider(height: 16),
          GestureDetector(
            onTap: () => _cancelOrder(context),
            child: const Row(children: [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
              SizedBox(width: 6),
              Text('إلغاء الطلب',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
          ),
        ],
        if (order.status == 'delivered') ...[
          const Divider(height: 16),
          GestureDetector(
            onTap: () => _showReviewDialog(context),
            child: const Row(children: [
              Icon(Icons.star_outline, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text('أضف تقييمك',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
          ),
        ],
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'shipped':
        return Colors.blue;
      case 'confirmed':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الطلب', textDirection: TextDirection.rtl),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟',
            textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('لا')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Get.back();
              await Get.find<OrderController>()
                  .updateOrderStatus(order.id, 'cancelled');
            },
            child:
                const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    double rating = 5;
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قيّم منتجك', textDirection: TextDirection.rtl),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StatefulBuilder(
              builder: (_, set) => Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.accent,
                    onChanged: (v) => set(() => rating = v),
                  )),
          TextField(
            controller: commentCtrl,
            decoration: const InputDecoration(hintText: 'تعليقك (اختياري)'),
            textDirection: TextDirection.rtl,
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              ctrl.submitReview(
                  order.id, rating.round(), commentCtrl.text.trim());
              Get.back();
            },
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
