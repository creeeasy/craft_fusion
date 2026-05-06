import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AdminSponsorshipsScreen extends StatefulWidget {
  const AdminSponsorshipsScreen({super.key});
  @override
  State<AdminSponsorshipsScreen> createState() =>
      _AdminSponsorshipsScreenState();
}

class _AdminSponsorshipsScreenState extends State<AdminSponsorshipsScreen>
    with SingleTickerProviderStateMixin {
  final _api = Get.find<ApiService>();
  late TabController _tabs;
  List _pending = [];
  List _reviewed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/sponsorships');
      final all =
          List<Map<String, dynamic>>.from(res.data['sponsorships'] ?? []);
      setState(() {
        _pending = all.where((s) => s['status'] == 'pending').toList();
        _reviewed = all.where((s) => s['status'] != 'pending').toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _review(int id, String status, {String? reason}) async {
    try {
      await _api.patch('/admin/sponsorships/$id', data: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reject_reason': reason,
      });
      Get.snackbar(
        status == 'approved' ? 'تمت الموافقة ✓' : 'تم الرفض',
        status == 'approved'
            ? 'الإعلان سيظهر للعملاء الآن'
            : 'تم إرسال سبب الرفض للحرفي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: status == 'approved'
            ? AppColors.primaryLight
            : const Color(0xFFFCEBEB),
        colorText:
            status == 'approved' ? AppColors.primaryDark : AppColors.error,
      );
      _load();
    } catch (_) {}
  }

  void _showRejectDialog(int id) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سبب الرفض', textDirection: TextDirection.rtl),
        content: TextField(
          controller: reasonCtrl,
          decoration:
              const InputDecoration(hintText: 'اكتب سبب الرفض للحرفي...'),
          textDirection: TextDirection.rtl,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Get.back();
              _review(id, 'rejected', reason: reasonCtrl.text.trim());
            },
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طلبات الترويج',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'بانتظار المراجعة (${_pending.length})'),
            Tab(text: 'تمت المراجعة (${_reviewed.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(_pending, showActions: true),
                _buildList(_reviewed, showActions: false),
              ],
            ),
    );
  }

  Widget _buildList(List items, {required bool showActions}) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
              showActions
                  ? 'لا توجد طلبات بانتظار المراجعة'
                  : 'لا توجد طلبات مراجعة',
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _SponsorshipCard(
          data: items[i],
          showActions: showActions,
          onApprove: () => _review(items[i]['id'], 'approved'),
          onReject: () => _showRejectDialog(items[i]['id']),
        ),
      ),
    );
  }
}

class _SponsorshipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SponsorshipCard({
    required this.data,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    final package = data['package'] ?? 'bronze';
    final photos = [data['photo_1'], data['photo_2'], data['photo_3']]
        .whereType<String>()
        .toList();

    final packageColors = {
      'bronze': const Color(0xFF795548),
      'silver': AppColors.silver,
      'gold': AppColors.gold,
    };
    final packageLabels = {
      'bronze': 'برونزي',
      'silver': 'فضي',
      'gold': 'ذهبي',
    };
    final pkgColor = packageColors[package] ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (data['artisan_name'] ?? 'ح')[0],
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['artisan_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(data['email'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]),
            ),
            // Package badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pkgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pkgColor.withOpacity(0.4)),
              ),
              child: Text(packageLabels[package] ?? package,
                  style: TextStyle(
                      color: pkgColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        // Promo title
        if (data['promo_title'] != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              data['promo_title'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary),
              textDirection: TextDirection.rtl,
            ),
          ),

        // Promo message
        if (data['promo_message'] != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              data['promo_message'],
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textDirection: TextDirection.rtl,
            ),
          ),

        // Photos
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: photos.map((url) {
                final fullUrl =
                    '${AppStrings.baseUrl.replaceAll('/api', '')}$url';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => _showPhotoFullscreen(context, fullUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: fullUrl,
                          height: 90,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 90,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textHint),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Info row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            const Icon(Icons.timer_outlined,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${data['duration_days']} يوم',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 14),
            const Icon(Icons.attach_money,
                size: 13, color: AppColors.textSecondary),
            Text(
                '${double.tryParse(data['amount'].toString())?.toStringAsFixed(0)} دج',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const Spacer(),
            _StatusChip(status: status),
          ]),
        ),

        // Reject reason (if rejected)
        if (status == 'rejected' && data['reject_reason'] != null)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCEBEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.error, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'سبب الرفض: ${data['reject_reason']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ]),
          ),

        // Action buttons
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCEBEB),
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: AppColors.error.withOpacity(0.3))),
                  ),
                  onPressed: onReject,
                  child: const Text('رفض',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onApprove,
                  child: const Text('موافقة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  void _showPhotoFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'pending': [AppColors.accentLight, AppColors.sponsored, 'قيد المراجعة'],
      'approved': [AppColors.primaryLight, AppColors.primary, 'موافق'],
      'rejected': [const Color(0xFFFCEBEB), AppColors.error, 'مرفوض'],
    };
    final vals =
        map[status] ?? [AppColors.background, AppColors.textSecondary, status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: vals[0] as Color, borderRadius: BorderRadius.circular(10)),
      child: Text(vals[2] as String,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: vals[1] as Color)),
    );
  }
}
