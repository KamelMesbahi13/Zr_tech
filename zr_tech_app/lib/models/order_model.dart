class OrderModel {
  final String orderId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final String categoryId;
  final String subcategoryId;
  final String shoppingType;
  final String firstName;
  final String lastName;
  final String phone;
  final String wilaya;
  final String address;
  final int quantity;
  final String shippingType; // 'home' or 'desk'
  final double deliveryPrice;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'delivered', 'cancelled'
  final int createdAt;

  OrderModel({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.categoryId,
    this.subcategoryId = '',
    required this.shoppingType,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.wilaya,
    required this.address,
    required this.quantity,
    required this.shippingType,
    required this.deliveryPrice,
    required this.totalPrice,
    this.status = 'pending',
    this.createdAt = 0,
  });

  String get customerFullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'shoppingType': shoppingType,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'wilaya': wilaya,
      'address': address,
      'quantity': quantity,
      'shippingType': shippingType,
      'deliveryPrice': deliveryPrice,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(String orderId, Map<String, dynamic> map) {
    return OrderModel(
      orderId: orderId,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      subcategoryId: map['subcategoryId'] ?? '',
      shoppingType: map['shoppingType'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      wilaya: map['wilaya'] ?? '',
      address: map['address'] ?? '',
      quantity: (map['quantity'] ?? 1) is int ? (map['quantity'] ?? 1) : 1,
      shippingType: map['shippingType'] ?? 'home',
      deliveryPrice: (map['deliveryPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] ?? 0) is int ? (map['createdAt'] ?? 0) : 0,
    );
  }
}
