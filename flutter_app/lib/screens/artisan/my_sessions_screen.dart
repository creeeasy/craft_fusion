import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/session_model.dart';
import 'add_session_screen.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  final _api = Get.find<ApiService>();
  List<SessionModel> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/sessions/my');
      final List<dynamic> data = res.data['sessions'] ?? [];
      setState(() {
        _sessions = data.map((json) => SessionModel.fromJson(json)).toList();
        _loading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(int id, bool current) async {
    try {
      await _api.patch('/sessions/$id', data: {'is_active': current ? 0 : 1});
      _load();
      Get.snackbar(
        'تم التحديث',
        current ? 'تم إيقاف الجلسة' : 'تم تفعيل الجلسة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryLight,
        colorText: AppColors.primaryDark,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث حالة الجلسة',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('جلساتي التعليمية',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 28),
            onPressed: () =>
                Get.to(() => const AddSessionScreen())?.then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.school_outlined,
                          size: 72, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text('لم تنشئ أي جلسة بعد',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('أنشئ جلستك الأولى'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                        onPressed: () => Get.to(() => const AddSessionScreen())
                            ?.then((_) => _load()),
                      ),
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) {
                      final session = _sessions[i];
                      final isActive = session.isActive;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isActive
                                  ? AppColors.border
                                  : AppColors.border.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session Image
                            if (session.imageUrl != null &&
                                session.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14)),
                                child: Image.network(
                                  '${AppStrings.baseUrl}${session.imageUrl}',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.broken_image,
                                        size: 40, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Switch
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          session.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isActive
                                                  ? AppColors.textPrimary
                                                  : AppColors.textHint),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                      Switch(
                                        value: isActive,
                                        activeColor: AppColors.primary,
                                        onChanged: (_) =>
                                            _toggleActive(session.id, isActive),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Category Chip
                                  if (session.categoryName != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(session.categoryIcon ?? '📚',
                                              style: const TextStyle(
                                                  fontSize: 10)),
                                          const SizedBox(width: 4),
                                          Text(
                                            session.categoryName!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  // Stats row
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _chip(
                                        Icons.people_outline,
                                        '${session.bookedCount} / ${session.maxParticipants} مشارك',
                                        session.isFull
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                      _chip(
                                        Icons.timer_outlined,
                                        '${session.durationMinutes} دقيقة',
                                        AppColors.textSecondary,
                                      ),
                                      _chip(
                                        Icons.attach_money,
                                        '${session.price.toInt()} دج',
                                        AppColors.primaryDark,
                                      ),
                                      if (session.avgRating != null)
                                        _chip(
                                          Icons.star,
                                          session.avgRating!.toStringAsFixed(1),
                                          Colors.amber,
                                        ),
                                    ],
                                  ),

                                  // Date
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 13,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.formattedFullDateTime,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),

                                  // Status badge
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: session.isUpcoming
                                          ? (session.isToday
                                              ? AppColors.primaryLight
                                              : AppColors.primaryLight
                                                  .withOpacity(0.5))
                                          : AppColors.textHint.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      session.statusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: session.isUpcoming
                                            ? (session.isToday
                                                ? AppColors.primaryDark
                                                : AppColors.primary)
                                            : AppColors.textHint,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // Capacity bar
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      children: [
                                        Container(
                                            height: 6,
                                            color: AppColors.primaryLight,
                                            width: double.infinity),
                                        FractionallySizedBox(
                                          widthFactor:
                                              session.capacityPercentage,
                                          child: Container(
                                              height: 6,
                                              color: session.isFull
                                                  ? AppColors.error
                                                  : AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Spots left text
                                  const SizedBox(height: 6),
                                  Text(
                                    session.spotsLeftText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: session.isAlmostFull
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                      fontWeight: session.isAlmostFull
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ]);
  }
}
