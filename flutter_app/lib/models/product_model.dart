class Product {
  final int id;
  final int artisanId;
  final String title;
  final String? titleAr;
  final String? description;
  final double price;
  final int stock;
  final String? image;
  final bool isActive;
  final int totalOrders;
  final String? artisanName;
  final String? location;
  final String? badge;
  final double avgRating;
  final bool isSponsored;
  final String? categoryName;
  final String? categoryNameAr;
  final String? icon;
  final String? createdAt;

  Product({
    required this.id,
    required this.artisanId,
    required this.title,
    this.titleAr,
    this.description,
    required this.price,
    required this.stock,
    this.image,
    required this.isActive,
    required this.totalOrders,
    this.artisanName,
    this.location,
    this.badge,
    required this.avgRating,
    required this.isSponsored,
    this.categoryName,
    this.categoryNameAr,
    this.icon,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        artisanId: j['artisan_id'],
        title: j['title'] ?? '',
        titleAr: j['title_ar'],
        description: j['description'],
        price: double.tryParse(j['price'].toString()) ?? 0,
        stock: j['stock'] ?? 0,
        image: j['image'],
        isActive: (j['is_active'] ?? 1) == 1,
        totalOrders: j['total_orders'] ?? 0,
        artisanName: j['artisan_name'],
        location: j['location'],
        badge: j['badge'],
        avgRating: double.tryParse(j['avg_rating'].toString()) ?? 0,
        isSponsored: (j['is_sponsored'] ?? 0) == 1,
        categoryName: j['category_name'],
        categoryNameAr: j['category_name_ar'],
        icon: j['icon'],
        createdAt: j['created_at'],
      );
}

class Category {
  final int id;
  final String name;
  final String? nameAr;
  final String? icon;

  Category({required this.id, required this.name, this.nameAr, this.icon});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'],
        name: j['name'] ?? '',
        nameAr: j['name_ar'],
        icon: j['icon'],
      );
}
