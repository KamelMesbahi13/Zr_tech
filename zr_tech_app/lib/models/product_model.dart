class ProductModel {
  final String id;
  final String name;
  final String image;
  final double price;
  final bool isAvailable;
  final String categoryId;
  final String description;
  final int createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.isAvailable,
    required this.categoryId,
    required this.description,
    this.createdAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'isAvailable': isAvailable,
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
      isAvailable: map['isAvailable'] ?? true,
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] ?? 0) is int ? (map['createdAt'] ?? 0) : 0,
    );
  }
}
