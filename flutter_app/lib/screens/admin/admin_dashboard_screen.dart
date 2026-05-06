import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import 'admin_artisans_screen.dart';
import 'admin_sponsorships_screen.dart';
import 'admin_revenue_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = Get.find<ApiService>();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/admin/dashboard');
      setState(() {
        _data = res.data;
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primaryDark,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.fromLTRB(20, 55, 20, 14),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة تحكم الإدارة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Naam Aya Admin',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => Get.find<AuthController>().logout(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildMenuItems(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'إجمالي المستخدمين',
        'value': '${_data?['total_users'] ?? 0}',
        'icon': Icons.people_outline,
        'color': AppColors.primary,
      },
      {
        'label': 'الحرفيون',
        'value': '${_data?['total_artisans'] ?? 0}',
        'icon': Icons.handyman_outlined,
        'color': AppColors.primaryDark,
      },
      {
        'label': 'بانتظار الموافقة',
        'value': '${_data?['pending_artisans'] ?? 0}',
        'icon': Icons.hourglass_empty,
        'color': AppColors.accent,
      },
      {
        'label': 'إجمالي الطلبات',
        'value': '${_data?['total_orders'] ?? 0}',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.blue,
      },
      {
        'label': 'إيرادات العمولة',
        'value':
            '${double.tryParse(_data?['revenue']?.toString() ?? '0')?.toStringAsFixed(0) ?? 0} دج',
        'icon': Icons.account_balance_wallet_outlined,
        'color': AppColors.success,
      },
      {
        'label': 'طلبات ترويج',
        'value': '${_data?['pending_sponsorships'] ?? 0}',
        'icon': Icons.star_outline,
        'color': AppColors.sponsored,
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22),
              const Spacer(),
              Text(
                s['value'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: s['color'] as Color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s['label'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    final items = [
      {
        'icon': Icons.how_to_reg_outlined,
        'label': 'إدارة الحرفيين',
        'sub': 'موافقة ورفض حسابات الحرفيين',
        'screen': const AdminArtisansScreen(),
      },
      {
        'icon': Icons.star_outline,
        'label': 'طلبات الترويج',
        'sub': 'مراجعة والموافقة على الترويج المدفوع',
        'screen': const AdminSponsorshipsScreen(),
      },
      {
        'icon': Icons.bar_chart_outlined,
        'label': 'الإيرادات',
        'sub': 'تقارير الأرباح الشهرية',
        'screen': const AdminRevenueScreen(),
      },
    ];
    return Column(
      children: items
          .map(
            (item) => GestureDetector(
              onTap: () => Get.to(() => item['screen'] as Widget),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item['sub'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
