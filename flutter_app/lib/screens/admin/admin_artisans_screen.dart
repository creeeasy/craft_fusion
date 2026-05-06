import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AdminArtisansScreen extends StatefulWidget {
  const AdminArtisansScreen({super.key});
  @override
  State<AdminArtisansScreen> createState() => _AdminArtisansScreenState();
}

class _AdminArtisansScreenState extends State<AdminArtisansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _api = Get.find<ApiService>();
  List _pending = [], _approved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _api.get('/admin/artisans', params: {'approved': 0});
      final a = await _api.get('/admin/artisans', params: {'approved': 1});
      setState(() {
        _pending = p.data['artisans'] ?? [];
        _approved = a.data['artisans'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id, bool approve) async {
    try {
      await _api
          .patch('/admin/artisans/$id/approve', data: {'approve': approve});
      Get.snackbar(approve ? 'تمت الموافقة' : 'تم الرفض', '',
          snackPosition: SnackPosition.BOTTOM);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الحرفيين',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Get.back()),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'بانتظار الموافقة (${_pending.length})'),
            Tab(text: 'موافق عليهم (${_approved.length})'),
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
                _buildList(_approved, showActions: false),
              ],
            ),
    );
  }

  Future<void> _assignBadge(int id, String badge) async {
    try {
      await _api.patch('/admin/artisans/\$id/badge', data: {'badge': badge});
      Get.snackbar('تم التحديث', 'تم تغيير الشارة إلى \$badge',
          snackPosition: SnackPosition.BOTTOM);
      _load();
    } catch (_) {}
  }

  Widget _buildList(List items, {required bool showActions}) {
    if (items.isEmpty)
      return const Center(
          child: Text('لا يوجد حرفيون',
              style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                radius: 22,
                child: Text((a['name'] ?? 'ح')[0],
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(a['email'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ]),
              ),
              if (a['badge'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: a['badge'] == 'gold'
                        ? AppColors.accentLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      a['badge'] == 'gold'
                          ? '★ ذهبي'
                          : a['badge'] == 'silver'
                              ? '◆ فضي'
                              : '✦ جديد',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: a['badge'] == 'gold'
                              ? AppColors.gold
                              : AppColors.silver)),
                ),
            ]),
            if (a['craft_type'] != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.handyman_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(a['craft_type'],
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (a['location'] != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textSecondary),
                  Text(a['location'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ]),
            ],
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approve(a['id'], false),
                    child: const Text('رفض', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approve(a['id'], true),
                    child: const Text('موافقة', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ]),
        );
      },
    );
  }
}

class _BadgeSelector extends StatefulWidget {
  final int artisanId;
  final String currentBadge;
  final Future<void> Function(int, String) onAssign;
  const _BadgeSelector({
    required this.artisanId,
    required this.currentBadge,
    required this.onAssign,
  });

  @override
  State<_BadgeSelector> createState() => _BadgeSelectorState();
}

class _BadgeSelectorState extends State<_BadgeSelector> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentBadge;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('الشارة:',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      _chip('new', '✦ جديد', AppColors.primary, AppColors.primaryLight),
      const SizedBox(width: 6),
      _chip('silver', '◆ فضي', AppColors.silver, Colors.grey.shade100),
      const SizedBox(width: 6),
      _chip('gold', '★ ذهبي', AppColors.gold, AppColors.accentLight),
    ]);
  }

  Widget _chip(String value, String label, Color textColor, Color bgColor) {
    final selected = _selected == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _selected = value);
        await widget.onAssign(widget.artisanId, value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? bgColor : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? textColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? textColor : AppColors.textSecondary,
            )),
      ),
    );
  }
}
