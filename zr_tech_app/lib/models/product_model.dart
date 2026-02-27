class ProductModel {
  final String id;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final int minQuantity;
  final String categoryId;
  final String description;
  final int createdAt;

  /// Computed from quantity: available if quantity > 0
  bool get isAvailable => quantity > 0;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 0,
    this.minQuantity = 1,
    required this.categoryId,
    required this.description,
    this.createdAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory ProductModel.fromMap(String id, String categoryId, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      categoryId: categoryId,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0) is int ? (map['quantity'] ?? 0) : 0,
      minQuantity: (map['minQuantity'] ?? 1) is int ? (map['minQuantity'] ?? 1) : 1,
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] ?? 0) is int ? (map['createdAt'] ?? 0) : 0,
    );
  }
}
