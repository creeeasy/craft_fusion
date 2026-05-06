class SessionModel {
  final int id;
  final int artisanId;
  final String artisanName;
  final String? artisanAvatar;
  final String? badge;
  final double? avgRating;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String title;
  final String? description;
  final double price;
  final int durationMinutes;
  final int maxParticipants;
  final int bookedCount;
  final DateTime scheduledAt;
  final String? imageUrl;
  final bool isActive;

  SessionModel({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    this.artisanAvatar,
    this.badge,
    this.avgRating,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    required this.title,
    this.description,
    required this.price,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.bookedCount,
    required this.scheduledAt,
    this.imageUrl,
    required this.isActive,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      artisanId: json['artisan_id'],
      artisanName: json['artisan_name'] ?? '',
      artisanAvatar: json['artisan_avatar'],
      badge: json['badge'],
      avgRating: json['avg_rating']?.toDouble(),
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      title: json['title'] ?? '',
      description: json['description'],
      price: _parsePrice(json['price']),
      durationMinutes: json['duration_minutes'] ?? 60,
      maxParticipants: json['max_participants'] ?? 5,
      bookedCount: json['booked_count'] ?? 0,
      scheduledAt: DateTime.parse(json['scheduled_at']),
      imageUrl: json['image_url'],
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artisan_id': artisanId,
      'artisan_name': artisanName,
      'artisan_avatar': artisanAvatar,
      'badge': badge,
      'avg_rating': avgRating,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'title': title,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'max_participants': maxParticipants,
      'booked_count': bookedCount,
      'scheduled_at': scheduledAt.toIso8601String(),
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Computed properties
  int get availableSpots => maxParticipants - bookedCount;

  double get capacityPercentage =>
      maxParticipants > 0 ? bookedCount / maxParticipants : 0;

  bool get isAlmostFull => availableSpots <= 3 && availableSpots > 0;

  bool get isFull => availableSpots == 0;

  String get spotsLeftText {
    if (isFull) return 'اكتمل العدد';
    if (availableSpots == 1) return 'متبقي مكان واحد فقط!';
    return 'متبقي $availableSpots أماكن';
  }

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  String get formattedDateTime {
    return '${scheduledAt.day}/${scheduledAt.month} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedFullDateTime {
    return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (isToday && isUpcoming) return 'اليوم';
    if (isUpcoming) return 'قادم';
    return 'انتهت';
  }
}

class BookingModel {
  final int id;
  final int sessionId;
  final String title;
  final String? imageUrl;
  final double price;
  final int durationMinutes;
  final DateTime scheduledAt;
  final String artisanName;
  final String? artisanAvatar;
  final String? categoryName;
  final String? categoryIcon;
  final int? rating;
  final String? review;
  final String status;

  BookingModel({
    required this.id,
    required this.sessionId,
    required this.title,
    this.imageUrl,
    required this.price,
    required this.durationMinutes,
    required this.scheduledAt,
    required this.artisanName,
    this.artisanAvatar,
    this.categoryName,
    this.categoryIcon,
    this.rating,
    this.review,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      sessionId: json['session_id'],
      title: json['title'] ?? '',
      imageUrl: json['image_url'],
      price: _parsePrice(json['price']),
      durationMinutes: json['duration_minutes'] ?? 60,
      scheduledAt: DateTime.parse(json['scheduled_at']),
      artisanName: json['artisan_name'] ?? '',
      artisanAvatar: json['artisan_avatar'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      rating: json['rating'],
      review: json['review'],
      status: json['status'] ?? 'booked',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'title': title,
      'image_url': imageUrl,
      'price': price,
      'duration_minutes': durationMinutes,
      'scheduled_at': scheduledAt.toIso8601String(),
      'artisan_name': artisanName,
      'artisan_avatar': artisanAvatar,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'rating': rating,
      'review': review,
      'status': status,
    };
  }

  // Computed properties
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get canRate =>
      scheduledAt.isBefore(DateTime.now()) &&
      rating == null &&
      status == 'booked';

  String get formattedDateTime {
    return '${scheduledAt.day}/${scheduledAt.month} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedFullDateTime {
    return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (isToday && isUpcoming) return 'اليوم';
    if (isUpcoming) return 'قادم';
    return 'انتهت';
  }
}

// Add to SessionModel class or in a separate file
extension DateTimeExtensions on DateTime {
  bool get isUpcoming => isAfter(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String formatTime() {
    return '${day}/${month} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (isToday && isUpcoming) return 'اليوم';
    if (isUpcoming) return 'قادم';
    return 'انتهت';
  }
}

double _parsePrice(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
