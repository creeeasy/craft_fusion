import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});
  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final _api = Get.find<ApiService>();
  List _monthly = [];
  double _sponsorshipRevenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/admin/revenue');
      setState(() {
        _monthly = res.data['monthly'] ?? [];
        _sponsorshipRevenue =
            double.tryParse(res.data['sponsorship_revenue'].toString()) ?? 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _totalCommission => _monthly.fold(
      0, (s, m) => s + (double.tryParse(m['commission'].toString()) ?? 0));
  double get _totalGross => _monthly.fold(
      0, (s, m) => s + (double.tryParse(m['gross'].toString()) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإيرادات',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  _summaryCard(
                      'إجمالي المبيعات',
                      '${_totalGross.toStringAsFixed(0)} دج',
                      AppColors.primary),
                  const SizedBox(width: 10),
                  _summaryCard(
                      'عمولة المنصة (5%)',
                      '${_totalCommission.toStringAsFixed(0)} دج',
                      AppColors.primaryDark),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _summaryCard(
                      'إيرادات الترويج',
                      '${_sponsorshipRevenue.toStringAsFixed(0)} دج',
                      AppColors.sponsored),
                  const SizedBox(width: 10),
                  _summaryCard(
                      'الإجمالي الكلي',
                      '${(_totalCommission + _sponsorshipRevenue).toStringAsFixed(0)} دج',
                      AppColors.success),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الإيرادات الشهرية',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        if (_monthly.isEmpty)
                          const Center(
                              child: Text('لا توجد بيانات بعد',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)))
                        else
                          ..._monthly.map((m) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(children: [
                                  Text(m['month'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                  const Spacer(),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('${m['orders']} طلب',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textHint)),
                                        Text(
                                            '${double.tryParse(m['commission'].toString())?.toStringAsFixed(0)} دج',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary)),
                                      ]),
                                ]),
                              )),
                      ]),
                ),
              ]),
            ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ]),
      ),
    );
  }
}
