import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/session_model.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/app_text_field.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = Get.find();

  List<SessionModel> _sessions = [];
  List<BookingModel> _myBookings = [];
  bool _loadingSessions = true;
  bool _loadingBookings = true;
  late TabController _tabController;

  // Filters
  int? _selectedCategory;
  String? _selectedSort;
  final List<Map<String, String>> _sortOptions = [
    {'value': 'date', 'label': 'الأقرب'},
    {'value': 'rating', 'label': 'الأعلى تقييماً'},
    {'value': 'price_asc', 'label': 'السعر: من الأقل'},
    {'value': 'price_desc', 'label': 'السعر: من الأعلى'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessions();
    _loadMyBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final res = await _api.getSessions(
        category: _selectedCategory?.toString(),
        sort: _selectedSort,
      );
      print(res);
      final List<dynamic> data = res.data['sessions'] ?? [];
      setState(() {
        _sessions = data.map((json) => SessionModel.fromJson(json)).toList();
        _loadingSessions = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _loadingSessions = false);
    }
  }

  Future<void> _loadMyBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final res = await _api.getMyBookings();
      final List<dynamic> data = res.data['bookings'] ?? [];
      setState(() {
        _myBookings = data.map((json) => BookingModel.fromJson(json)).toList();
        _loadingBookings = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _loadingBookings = false);
    }
  }

  Future<void> _bookSession(int sessionId) async {
    try {
      await _api.bookSession(sessionId);
      await _loadSessions();
      await _loadMyBookings();
      if (mounted) {
        Get.snackbar(
          'تم الحجز',
          'تم حجز الجلسة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight,
          colorText: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      String message = 'حدث خطأ أثناء الحجز';
      if (e is DioException) {
        message = e.response?.data['message'] ?? message;
      }
      if (mounted) {
        Get.snackbar(
          'خطأ',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
        );
      }
    }
  }

  Future<void> _cancelBooking(int sessionId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد من إلغاء حجز هذه الجلسة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('نعم', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.cancelBooking(sessionId);
      await _loadMyBookings();
      if (mounted) {
        Get.snackbar(
          'تم الإلغاء',
          'تم إلغاء حجز الجلسة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight,
          colorText: AppColors.primaryDark,
        );
      }
    } catch (e) {
      String message = 'حدث خطأ أثناء الإلغاء';
      if (e is DioException) {
        message = e.response?.data['message'] ?? message;
      }
      if (mounted) {
        Get.snackbar(
          'خطأ',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
        );
      }
    }
  }

  Future<void> _rateSession(int sessionId, String title) async {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: Text('تقييم الجلسة: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('كيف كانت تجربتك؟'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return StarRating(
                  rating: selectedRating.toDouble(),
                  size: 32,
                  interactive: true,
                  onRatingChanged: (rating) {
                    setState(() {
                      selectedRating = rating;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: reviewController,
              label: 'تعليقك (اختياري)',
              hint: 'شاركنا رأيك عن الجلسة',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedRating == 0) {
                Get.snackbar('خطأ', 'الرجاء اختيار تقييم');
                return;
              }
              Get.back();

              try {
                await _api.rateSession(sessionId,
                    rating: selectedRating,
                    review: reviewController.text.isEmpty
                        ? null
                        : reviewController.text);
                await _loadMyBookings();
                Get.snackbar('شكراً', 'تم تقييم الجلسة بنجاح');
              } catch (e) {
                Get.snackbar('خطأ', 'فشل في تقييم الجلسة');
              }
            },
            child: const Text('إرسال'),
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
        title: const Text(
          'الجلسات التعليمية',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'الجلسات المتاحة'),
            Tab(text: 'حجوزاتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSessions(),
          _buildMyBookings(),
        ],
      ),
    );
  }

  Widget _buildAvailableSessions() {
    if (_loadingSessions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      children: [
        // Category Filter
        _buildCategoryFilter(),
        // Sort Dropdown
        _buildSortDropdown(),
        // Sessions List
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد جلسات متاحة حالياً',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'سيتم إضافة جلسات جديدة قريباً',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _SessionCard(
                        session: session,
                        onBook: () => _bookSession(session.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return FutureBuilder(
      future: _api.get('/products/categories'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final categories = snapshot.data!.data['categories'] ?? [];

        return SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterChip('الكل', null);
              }
              final cat = categories[index - 1];
              return _buildFilterChip(
                '${cat['icon'] ?? '📚'} ${cat['name'] ?? ''}',
                cat['id'],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int? categoryId) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = isSelected ? null : categoryId;
          });
          _loadSessions();
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('ترتيب حسب:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              value: _selectedSort,
              hint: const Text('الأقرب', style: TextStyle(fontSize: 12)),
              underline: const SizedBox(),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(option['label']!,
                      style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSort = value;
                });
                _loadSessions();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookings() {
    if (_loadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'لا توجد حجوزات',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'قم بحجز جلسة من قسم الجلسات المتاحة',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myBookings.length,
        itemBuilder: (context, index) {
          final booking = _myBookings[index];
          return _BookingCard(
            booking: booking,
            onCancel: () => _cancelBooking(booking.sessionId),
            onRate: () => _rateSession(booking.sessionId, booking.title),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onBook;

  const _SessionCard({
    required this.session,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Image
          if (session.imageUrl != null && session.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                '${AppStrings.baseUrl}${session.imageUrl}',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
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
                // Title and Price
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: session.isFull
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${session.price.toInt()} دج',
                        style: TextStyle(
                          color: session.isFull
                              ? AppColors.error
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category and Rating
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (session.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(session.categoryIcon ?? '📚',
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              session.categoryName!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    if (session.avgRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              session.avgRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Artisan and Duration
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.artisanName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${session.durationMinutes} دقيقة',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Capacity and Status
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${session.bookedCount} / ${session.maxParticipants} مشارك',
                      style: TextStyle(
                        fontSize: 12,
                        color: session.isFull
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: session.isFull
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: session.isUpcoming
                            ? (session.scheduledAt.isToday
                                ? AppColors.primaryLight
                                : AppColors.primaryLight.withOpacity(0.5))
                            : AppColors.textHint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: session.isUpcoming
                              ? (session.scheduledAt.isToday
                                  ? AppColors.primaryDark
                                  : AppColors.primary)
                              : AppColors.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Date and Time
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      session.formattedDateTime,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                // Capacity Progress Bar
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: AppColors.primaryLight,
                        width: double.infinity,
                      ),
                      FractionallySizedBox(
                        widthFactor: session.capacityPercentage,
                        child: Container(
                          height: 6,
                          color: session.isAlmostFull
                              ? AppColors.error
                              : (session.isFull
                                  ? Colors.grey
                                  : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
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
                const SizedBox(height: 12),

                // Book Button
                if (!session.isFull && session.isUpcoming)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onBook,
                      child: const Text('احجز مكانك'),
                    ),
                  )
                else if (session.isFull)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'اكتمل العدد',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: booking.isUpcoming ? AppColors.primary : AppColors.border,
          width: booking.isUpcoming ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.isUpcoming
                      ? (booking.isToday
                          ? AppColors.primaryLight
                          : AppColors.primaryLight.withOpacity(0.7))
                      : AppColors.textHint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: booking.isUpcoming
                        ? (booking.isToday
                            ? AppColors.primaryDark
                            : AppColors.primary)
                        : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Artisan
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.artisanName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Price and Duration
          Row(
            children: [
              const Icon(Icons.price_change,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${booking.price.toInt()} دج',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${booking.durationMinutes} دقيقة',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Date and Time
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                booking.formattedDateTime,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          // Rating Display (if rated)
          if (booking.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                StarRating(rating: booking.rating!.toDouble(), size: 16),
                const SizedBox(width: 8),
                if (booking.review != null)
                  Expanded(
                    child: Text(
                      booking.review!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              if (booking.isUpcoming)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: onCancel,
                    child: const Text('إلغاء الحجز'),
                  ),
                ),
              if (booking.canRate) ...[
                if (booking.isUpcoming) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: onRate,
                    child: const Text('تقييم الجلسة'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
