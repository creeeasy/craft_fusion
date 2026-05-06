class Order {
  final int id;
  final int clientId;
  final int artisanId;
  final int productId;
  final int quantity;
  final double totalPrice;
  final String status;
  final String? createdAt;
  final String? productTitle;
  final String? productImage;
  final double? unitPrice;
  final String? artisanName;
  final String? clientName;

  Order({
    required this.id,
    required this.clientId,
    required this.artisanId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.createdAt,
    this.productTitle,
    this.productImage,
    this.unitPrice,
    this.artisanName,
    this.clientName,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        clientId: j['client_id'],
        artisanId: j['artisan_id'],
        productId: j['product_id'],
        quantity: j['quantity'] ?? 1,
        totalPrice: double.tryParse(j['total_price'].toString()) ?? 0,
        status: j['status'] ?? 'pending',
        createdAt: j['created_at'],
        productTitle: j['title'],
        productImage: j['image'],
        unitPrice: j['unit_price'] != null
            ? double.tryParse(j['unit_price'].toString())
            : null,
        artisanName: j['artisan_name'],
        clientName: j['client_name'],
      );

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
