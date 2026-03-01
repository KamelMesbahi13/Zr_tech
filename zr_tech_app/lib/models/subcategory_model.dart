class SubcategoryModel {
  final String id;
  final String name;
  final String image;
  final int order;
  final String categoryId;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'order': order,
    };
  }

  factory SubcategoryModel.fromMap(String id, String categoryId, Map<String, dynamic> map) {
    return SubcategoryModel(
      id: id,
      categoryId: categoryId,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}
