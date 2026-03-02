class ProductModel {
  final String id;
  final String name;
  final List<String> images;
  final double price;
  final int quantity;
  final int minQuantity;
  final String categoryId;
  final String subcategoryId;
  final String description;
  final int createdAt;

  // New optional fields
  final String? color;
  final String? condition; // 'original' or 'not_original'
  final String? box; // 'with_box' or 'without_box'
  final String? conditionStatus; // 'new' or 'used'
  final String? charger; // 'with_charger' or 'without_charger'
  final String? headphones; // 'with_headphones' or 'without_headphones'
  final String? warranty; // '1_month', '3_months', '6_months', '1_year', '2_years'
  final double? detailMarketPrice; // Retail price shown for gros products
  final String? countryOfOrigin; // Country code e.g. 'CN', 'KR', 'DZ'

  /// Backward-compat getter: returns first image or empty string
  String get image => images.isNotEmpty ? images.first : '';

  /// Computed from quantity: available if quantity > 0
  bool get isAvailable => quantity > 0;

  ProductModel({
    required this.id,
    required this.name,
    this.images = const [],
    required this.price,
    this.quantity = 0,
    this.minQuantity = 1,
    required this.categoryId,
    this.subcategoryId = '',
    required this.description,
    this.createdAt = 0,
    this.color,
    this.condition,
    this.box,
    this.conditionStatus,
    this.charger,
    this.headphones,
    this.warranty,
    this.detailMarketPrice,
    this.countryOfOrigin,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'images': images,
      'price': price,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'description': description,
      'createdAt': createdAt,
    };
    // Only write optional fields when they have values
    if (color != null) map['color'] = color;
    if (condition != null) map['condition'] = condition;
    if (box != null) map['box'] = box;
    if (conditionStatus != null) map['conditionStatus'] = conditionStatus;
    if (charger != null) map['charger'] = charger;
    if (headphones != null) map['headphones'] = headphones;
    if (warranty != null) map['warranty'] = warranty;
    if (detailMarketPrice != null) map['detailMarketPrice'] = detailMarketPrice;
    if (countryOfOrigin != null) map['countryOfOrigin'] = countryOfOrigin;
    return map;
  }

  factory ProductModel.fromMap(String id, String categoryId, Map<String, dynamic> map, {String subcategoryId = ''}) {
    // Handle images: support both new 'images' list and legacy single 'image' string
    List<String> imagesList = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        imagesList = List<String>.from(map['images']);
      }
    } else if (map['image'] != null && (map['image'] as String).isNotEmpty) {
      imagesList = [map['image'] as String];
    }

    return ProductModel(
      id: id,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      name: map['name'] ?? '',
      images: imagesList,
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0) is int ? (map['quantity'] ?? 0) : 0,
      minQuantity: (map['minQuantity'] ?? 1) is int ? (map['minQuantity'] ?? 1) : 1,
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] ?? 0) is int ? (map['createdAt'] ?? 0) : 0,
      color: map['color'] as String?,
      condition: map['condition'] as String?,
      box: map['box'] as String?,
      conditionStatus: map['conditionStatus'] as String?,
      charger: map['charger'] as String?,
      headphones: map['headphones'] as String?,
      warranty: map['warranty'] as String?,
      detailMarketPrice: map['detailMarketPrice'] != null ? (map['detailMarketPrice'] as num).toDouble() : null,
      countryOfOrigin: map['countryOfOrigin'] as String?,
    );
  }
}
