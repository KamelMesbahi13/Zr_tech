class CategoryModel {
  final String id;
  final String name;
  final String image;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'order': order,
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}
