import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../screens/client/learn_screen.dart';

class UpcomingSessionsWidget extends StatefulWidget {
  const UpcomingSessionsWidget({super.key});

  @override
  State<UpcomingSessionsWidget> createState() => _UpcomingSessionsWidgetState();
}

class _UpcomingSessionsWidgetState extends State<UpcomingSessionsWidget> {
  final ApiService _api = Get.find();
  List<dynamic> _upcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    try {
      final res = await _api.getUpcomingBookings();
      setState(() {
        _upcoming = res.data['upcoming'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (_upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.event_available, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'جلساتك القادمة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _upcoming.length,
            itemBuilder: (context, index) {
              final booking = _upcoming[index];
              final date = DateTime.tryParse(booking['scheduled_at'] ?? '');
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.to(() => const LearnScreen()),
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        Container(
                          width: 90,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                            image: booking['image_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        '${AppStrings.baseUrl}${booking['image_url']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: booking['image_url'] == null
                              ? Container(
                                  color: AppColors.primaryLight,
                                  child: const Icon(
                                    Icons.school,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  booking['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 12,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        booking['artisan_name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (date != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 12,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
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
                                      const Icon(Icons.access_time,
                                          size: 10, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${booking['duration_minutes'] ?? 60} دقيقة',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
