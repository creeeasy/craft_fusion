import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  static const _steps = ['pending', 'confirmed', 'shipped', 'delivered'];

  static const _stepLabels = {
    'pending': 'تم تقديم الطلب',
    'confirmed': 'تأكيد الطلب',
    'shipped': 'في الطريق إليك',
    'delivered': 'تم التسليم',
  };

  static const _stepSubLabels = {
    'pending': 'طلبك وصل للحرفي وبانتظار التأكيد',
    'confirmed': 'الحرفي أكد طلبك وبدأ التحضير',
    'shipped': 'طلبك في الطريق إليك',
    'delivered': 'استلمت طلبك بنجاح',
  };

  static const _stepIcons = {
    'pending': Icons.receipt_long_outlined,
    'confirmed': Icons.check_circle_outline,
    'shipped': Icons.local_shipping_outlined,
    'delivered': Icons.celebration_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        order.status == 'cancelled' ? -1 : _steps.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تتبع الطلب',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderCard(),
            const SizedBox(height: 20),
            if (order.status == 'cancelled')
              _buildCancelledBanner()
            else
              _buildStepper(currentIndex),
            const SizedBox(height: 20),
            _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                order.productTitle ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('طلب رقم #${order.id}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
        const Divider(height: 20),
        Row(children: [
          const Icon(Icons.person_outline,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('الحرفي: ${order.artisanName ?? ''}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text('${order.totalPrice.toStringAsFixed(0)} دج',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 16)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.inventory_2_outlined,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('الكمية: ${order.quantity}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          _buildStatusPill(order.status),
        ]),
      ]),
    );
  }

  Widget _buildStatusPill(String status) {
    final colors = {
      'pending': [AppColors.accentLight, AppColors.sponsored],
      'confirmed': [AppColors.primaryLight, AppColors.primary],
      'shipped': [const Color(0xFFE6F1FB), const Color(0xFF185FA5)],
      'delivered': [AppColors.primaryLight, AppColors.primaryDark],
      'cancelled': [const Color(0xFFFCEBEB), AppColors.error],
    };
    final pair =
        colors[status] ?? [AppColors.background, AppColors.textSecondary];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pair[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusAr(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: pair[1]),
      ),
    );
  }

  String _statusAr(String s) {
    switch (s) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return s;
    }
  }

  Widget _buildCancelledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.cancel_outlined, color: AppColors.error, size: 32),
        const SizedBox(width: 12),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تم إلغاء الطلب',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.error)),
            SizedBox(height: 4),
            Text('تم إلغاء هذا الطلب من قبل الحرفي.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textDirection: TextDirection.rtl),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStepper(int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة الطلب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) {
            final isDone = i <= currentIndex;
            final isActive = i == currentIndex;
            final isLast = i == _steps.length - 1;
            final step = _steps[i];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: dot + line
                Column(children: [
                  _buildStepDot(
                      isDone: isDone,
                      isActive: isActive,
                      icon: _stepIcons[step]!),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 44,
                      color: isDone && i < currentIndex
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                ]),
                const SizedBox(width: 14),
                // Right side: label + sublabel
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepLabels[step]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDone
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _stepSubLabels[step]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepDot({
    required bool isDone,
    required bool isActive,
    required IconData icon,
  }) {
    if (isActive) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );
    }
    if (isDone) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.primary, size: 18),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Icon(icon, color: AppColors.textHint, size: 18),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تفاصيل الطلب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _detailRow('رقم الطلب', '#${order.id}'),
          _detailRow('المنتج', order.productTitle ?? ''),
          _detailRow('الحرفي', order.artisanName ?? ''),
          _detailRow('الكمية', '${order.quantity}'),
          _detailRow(
              'السعر الإجمالي', '${order.totalPrice.toStringAsFixed(0)} دج'),
          if (order.createdAt != null)
            _detailRow('تاريخ الطلب', _formatDate(order.createdAt!)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              textDirection: TextDirection.rtl),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
