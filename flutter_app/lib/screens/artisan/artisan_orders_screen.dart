import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class ArtisanOrdersScreen extends StatefulWidget {
  const ArtisanOrdersScreen({super.key});
  @override
  State<ArtisanOrdersScreen> createState() => _ArtisanOrdersScreenState();
}

class _ArtisanOrdersScreenState extends State<ArtisanOrdersScreen> {
  final _api = Get.find<ApiService>();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/orders/artisan');
      setState(() {
        _orders = res.data['orders'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await _api.patch('/orders/$orderId/status', data: {'status': status});
      Get.snackbar(
        'تم التحديث',
        'تم تغيير حالة الطلب',
        snackPosition: SnackPosition.BOTTOM,
      );
      _load();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        (e as dynamic).response?.data['message'] ?? 'حدث خطأ',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الطلبات الواردة',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات بعد',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (_, i) => _OrderCard(
                  order: _orders[i],
                  onUpdateStatus: _updateStatus,
                ),
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(int, String) onUpdateStatus;
  const _OrderCard({required this.order, required this.onUpdateStatus});

  static const _statusColors = {
    'pending': AppColors.accent,
    'confirmed': AppColors.primary,
    'shipped': Colors.blue,
    'delivered': AppColors.success,
    'cancelled': AppColors.error,
  };

  static const _statusLabels = {
    'pending': 'قيد الانتظار',
    'confirmed': 'مؤكد',
    'shipped': 'في الطريق',
    'delivered': 'تم التسليم',
    'cancelled': 'ملغي',
  };

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final color = _statusColors[status] ?? AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Text(
                order['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textDirection: TextDirection.rtl,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabels[status] ?? status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                order['client_name'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (order['client_phone'] != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order['client_phone'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'الكمية: ${order['quantity']}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const Spacer(),
              Text(
                '${double.tryParse(order['total_price'].toString())?.toStringAsFixed(0)} دج',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (_nextStatuses(status).isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _nextStatuses(status)
                  .map(
                    (s) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusColors[s] ?? AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onUpdateStatus(order['id'], s),
                      child: Text(
                        _statusLabels[s] ?? s,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _nextStatuses(String current) {
    switch (current) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['shipped'];
      case 'shipped':
        return ['delivered'];
      default:
        return [];
    }
  }
}
