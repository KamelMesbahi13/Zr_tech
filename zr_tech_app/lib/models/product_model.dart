class ProductModel {
  final String id;
  final String name;
  final String image;
  final double price;
  final bool isAvailable;
  final String categoryId;
  final String description;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.isAvailable,
    required this.categoryId,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'isAvailable': isAvailable,
      'description': description,
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
    );
  }
}
