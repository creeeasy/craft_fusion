import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class ArtisanEarningsScreen extends StatefulWidget {
  const ArtisanEarningsScreen({super.key});

  @override
  State<ArtisanEarningsScreen> createState() => _ArtisanEarningsScreenState();
}

class _ArtisanEarningsScreenState extends State<ArtisanEarningsScreen> {
  final _api = Get.find<ApiService>();
  List<dynamic> _orders = [];
  bool _loading = true;

  // Revenue breakdown
  double _totalGross = 0;
  double _totalCommission = 0;
  double _totalNet = 0;
  int _totalDelivered = 0;
  int _totalPending = 0;
  Map<String, _MonthSummary> _monthly = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/orders/artisan');
      final orders = List<Map<String, dynamic>>.from(res.data['orders'] ?? []);

      double gross = 0, commission = 0;
      int delivered = 0, pending = 0;
      final Map<String, _MonthSummary> monthly = {};

      for (final o in orders) {
        final amount = double.tryParse(o['total_price'].toString()) ?? 0;
        final status = o['status'] as String;
        final date = o['created_at'] != null
            ? DateTime.tryParse(o['created_at']) ?? DateTime.now()
            : DateTime.now();
        final monthKey =
            '${date.year}/${date.month.toString().padLeft(2, '0')}';

        if (status == 'delivered') {
          gross += amount;
          commission += amount * 0.05;
          delivered++;
          monthly.putIfAbsent(monthKey, () => _MonthSummary(monthKey));
          monthly[monthKey]!.gross += amount;
          monthly[monthKey]!.net += amount * 0.95;
          monthly[monthKey]!.orders++;
        } else if (status == 'pending' || status == 'confirmed') {
          pending++;
        }
      }

      setState(() {
        _orders = orders;
        _totalGross = gross;
        _totalCommission = commission;
        _totalNet = gross - commission;
        _totalDelivered = delivered;
        _totalPending = pending;
        _monthly = Map.fromEntries(
          monthly.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
        );
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأرباح والمبيعات',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildCommissionInfo(),
                    const SizedBox(height: 20),
                    _buildMonthlyBreakdown(),
                    const SizedBox(height: 20),
                    _buildRecentOrders(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(children: [
      // Big net earnings card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Text('صافي أرباحك',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${_totalNet.toStringAsFixed(0)} دج',
            style: const TextStyle(
                color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'بعد خصم عمولة المنصة (5%)',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _miniCard(
          label: 'إجمالي المبيعات',
          value: '${_totalGross.toStringAsFixed(0)} دج',
          icon: Icons.trending_up,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 10),
        _miniCard(
          label: 'عمولة المنصة',
          value: '${_totalCommission.toStringAsFixed(0)} دج',
          icon: Icons.percent,
          color: AppColors.accent,
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _miniCard(
          label: 'طلبات مكتملة',
          value: '$_totalDelivered',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        _miniCard(
          label: 'طلبات قيد التنفيذ',
          value: '$_totalPending',
          icon: Icons.hourglass_empty,
          color: Colors.orange,
        ),
      ]),
    ]);
  }

  Widget _miniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 2),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildCommissionInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.sponsored, size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'تحتفظ المنصة بنسبة 5% من كل عملية بيع كعمولة لدعم الخدمات المقدمة.',
            style: TextStyle(
                fontSize: 12, color: AppColors.sponsored, height: 1.5),
            textDirection: TextDirection.rtl,
          ),
        ),
      ]),
    );
  }

  Widget _buildMonthlyBreakdown() {
    if (_monthly.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الأرباح الشهرية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('بعد خصم العمولة',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ..._monthly.entries.map((e) {
            final summary = e.value;
            final maxNet = _monthly.values
                .map((s) => s.net)
                .reduce((a, b) => a > b ? a : b);
            final barFraction =
                maxNet > 0 ? (summary.net / maxNet).clamp(0.05, 1.0) : 0.05;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatMonth(e.key),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      Row(children: [
                        Text('${summary.orders} طلب',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 8),
                        Text('${summary.net.toStringAsFixed(0)} دج',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      Container(
                          height: 8,
                          color: AppColors.primaryLight,
                          width: double.infinity),
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recent = _orders
        .where((o) =>
            o['status'] == 'delivered' ||
            o['status'] == 'pending' ||
            o['status'] == 'confirmed')
        .take(10)
        .toList();

    if (recent.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر المعاملات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...recent.map((o) {
            final amount = double.tryParse(o['total_price'].toString()) ?? 0;
            final status = o['status'] as String;
            final isDelivered = status == 'delivered';
            final net = amount * 0.95;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? AppColors.primaryLight
                        : AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDelivered
                        ? Icons.check_circle_outline
                        : Icons.hourglass_empty,
                    color:
                        isDelivered ? AppColors.primary : AppColors.sponsored,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl),
                      Text(o['client_name'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    isDelivered
                        ? '+ ${net.toStringAsFixed(0)} دج'
                        : '${amount.toStringAsFixed(0)} دج',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDelivered
                            ? AppColors.primary
                            : AppColors.textSecondary),
                  ),
                  Text(
                    isDelivered ? 'مكتمل' : _statusAr(status),
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            isDelivered ? AppColors.primary : AppColors.accent),
                  ),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
  }

  String _statusAr(String s) {
    switch (s) {
      case 'pending':
        return 'انتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'شحن';
      default:
        return s;
    }
  }

  String _formatMonth(String key) {
    final parts = key.split('/');
    if (parts.length != 2) return key;
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }
}

class _MonthSummary {
  final String key;
  double gross = 0;
  double net = 0;
  int orders = 0;
  _MonthSummary(this.key);
}
