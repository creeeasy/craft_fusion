import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naam_aya/screens/artisan/add_session_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../artisan/my_listings_screen.dart';
import '../artisan/artisan_orders_screen.dart';
import '../artisan/add_product_screen.dart';
import '../artisan/request_sponsorship_screen.dart';
import '../artisan/artisan_earnings_screen.dart';
import '../artisan/edit_profile_screen.dart';
import '../artisan/my_sessions_screen.dart';

class ArtisanDashboardScreen extends StatefulWidget {
  const ArtisanDashboardScreen({super.key});

  @override
  State<ArtisanDashboardScreen> createState() => _ArtisanDashboardScreenState();
}

class _ArtisanDashboardScreenState extends State<ArtisanDashboardScreen> {
  final _api = Get.find<ApiService>();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final ordersRes = await _api.get('/orders/artisan');
      final orders = ordersRes.data['orders'] as List;
      final earnings = orders
          .where((o) => o['status'] == 'delivered')
          .fold<double>(
              0,
              (s, o) =>
                  s + double.tryParse(o['total_price'].toString())! * 0.95);

      // Load sessions stats
      final sessionsRes = await _api.get('/sessions/my');
      final sessions = sessionsRes.data['sessions'] as List;
      final totalSessions = sessions.length;
      final upcomingSessions = sessions.where((s) {
        final date = DateTime.tryParse(s['scheduled_at'] ?? '');
        return date != null &&
            date.isAfter(DateTime.now()) &&
            s['is_active'] == 1;
      }).length;
      final totalParticipants = sessions.fold<int>(
        0,
        (sum, s) => sum + ((s['booked_count'] as num?)?.toInt() ?? 0),
      );
      setState(() {
        _stats = {
          'total_orders': orders.length,
          'pending': orders.where((o) => o['status'] == 'pending').length,
          'earnings': earnings,
          'total_sessions': totalSessions,
          'upcoming_sessions': upcomingSessions,
          'total_participants': totalParticipants,
        };
        _loading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Text((user?['name'] ?? 'ح')[0],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مرحباً، ${user?['name'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const Text('لوحة تحكم الحرفي',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ]),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.white),
                          onPressed: () =>
                              Get.to(() => const EditProfileScreen()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => Get.find<AuthController>().logout(),
                        ),
                      ]),
                    ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildStats(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildMenuItems(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: [
        // First row - Orders stats
        Row(children: [
          _statCard('الطلبات', '${_stats?['total_orders'] ?? 0}',
              Icons.receipt_long_outlined, AppColors.primary),
          const SizedBox(width: 10),
          _statCard('قيد الانتظار', '${_stats?['pending'] ?? 0}',
              Icons.hourglass_empty, AppColors.accent),
          const SizedBox(width: 10),
          _statCard(
              'الأرباح',
              '${(_stats?['earnings'] as double? ?? 0).toStringAsFixed(0)} دج',
              Icons.account_balance_wallet_outlined,
              AppColors.primaryDark),
        ]),
        const SizedBox(height: 12),
        // Second row - Sessions stats
        Row(children: [
          _statCard('جلساتي', '${_stats?['total_sessions'] ?? 0}',
              Icons.school_outlined, AppColors.primary),
          const SizedBox(width: 10),
          _statCard('قادمة', '${_stats?['upcoming_sessions'] ?? 0}',
              Icons.event_available, AppColors.accent),
          const SizedBox(width: 10),
          _statCard('مشاركون', '${_stats?['total_participants'] ?? 0}',
              Icons.people_outline, AppColors.primaryDark),
        ]),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة منتج'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Get.to(() => const AddProductScreen()),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.school_outlined, size: 18),
          label: const Text('جلسة جديدة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentLight,
            foregroundColor: AppColors.sponsored,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
          onPressed: () => Get.to(() => const AddSessionScreen()),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.star_outline, size: 18),
          label: const Text('طلب ترويج'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentLight,
            foregroundColor: AppColors.sponsored,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
          onPressed: () => Get.to(() => const RequestSponsorshipScreen()),
        ),
      ),
    ]);
  }

  Widget _buildMenuItems() {
    final items = [
      {
        'icon': Icons.school_outlined,
        'label': 'جلساتي التعليمية',
        'sub': 'إدارة الجلسات التي تقدمها',
        'screen': const MySessionsScreen()
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'منتجاتي',
        'sub': 'إدارة قائمة منتجاتك',
        'screen': const MyListingsScreen()
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'الطلبات الواردة',
        'sub': 'عرض وإدارة طلبات العملاء',
        'screen': const ArtisanOrdersScreen()
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'الأرباح والمبيعات',
        'sub': 'تقرير مفصل عن إيراداتك',
        'screen': const ArtisanEarningsScreen()
      },
    ];

    return Column(
      children: items
          .map((item) => GestureDetector(
                onTap: () => Get.to(() => item['screen'] as Widget),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item['icon'] as IconData,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(item['sub'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ]),
                    const Spacer(),
                    const Icon(Icons.chevron_left, color: AppColors.textHint),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}
