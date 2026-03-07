import 'package:flutter/foundation.dart';

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

  // ── Variable product fields ──
  // Options: list of attribute definitions
  // e.g. [{"name": "الحجم", "values": ["S", "M", "L"]}, {"name": "اللون", "values": ["أحمر", "أزرق"]}]
  final List<Map<String, dynamic>>? options;

  // Variants: list of variant combinations
  // e.g. [{"combination": {"الحجم": "S", "اللون": "أحمر"}, "price": 500, "quantity": 10}, ...]
  final List<Map<String, dynamic>>? variants;

  /// Whether this is a variable product
  bool get isVariable => variants != null && variants!.isNotEmpty;

  /// Backward-compat getter: returns first image or empty string
  String get image => images.isNotEmpty ? images.first : '';

  /// Computed from quantity: available if quantity > 0
  bool get isAvailable => quantity > 0;

  /// For variable products, get the price range string
  String get priceRange {
    if (!isVariable) return price.toStringAsFixed(0);
    final prices = variants!.map((v) => (v['price'] as num).toDouble()).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    if (minP == maxP) return minP.toStringAsFixed(0);
    return '${minP.toStringAsFixed(0)} - ${maxP.toStringAsFixed(0)}';
  }

  /// Get a specific variant's price
  double getVariantPrice(Map<String, String> combination) {
    if (!isVariable) return price;
    final v = variants!.firstWhere(
      (v) => mapEquals(Map<String, String>.from(v['combination'] as Map), combination),
      orElse: () => {'price': price},
    );
    return (v['price'] as num).toDouble();
  }

  /// Get a specific variant's quantity
  int getVariantQuantity(Map<String, String> combination) {
    if (!isVariable) return quantity;
    final v = variants!.firstWhere(
      (v) => mapEquals(Map<String, String>.from(v['combination'] as Map), combination),
      orElse: () => {'quantity': 0},
    );
    return (v['quantity'] as num).toInt();
  }

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
    this.options,
    this.variants,
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
    if (options != null && options!.isNotEmpty) map['options'] = options;
    if (variants != null && variants!.isNotEmpty) map['variants'] = variants;
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

    // Parse options
    List<Map<String, dynamic>>? optionsList;
    if (map['options'] != null && map['options'] is List) {
      optionsList = (map['options'] as List).map((o) {
        if (o is Map) {
          return Map<String, dynamic>.from(o);
        }
        return <String, dynamic>{};
      }).toList();
    }

    // Parse variants
    List<Map<String, dynamic>>? variantsList;
    if (map['variants'] != null && map['variants'] is List) {
      variantsList = (map['variants'] as List).map((v) {
        if (v is Map) {
          return Map<String, dynamic>.from(v);
        }
        return <String, dynamic>{};
      }).toList();
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
      options: optionsList,
      variants: variantsList,
    );
  }
}
