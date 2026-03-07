import 'package:flutter/foundation.dart';
import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final String shoppingType; // 'gros' or 'detail'
  int cartQuantity;

  /// Selected variant combination for variable products
  /// e.g. {"الحجم": "S", "اللون": "أحمر"}
  final Map<String, String>? selectedVariant;

  CartItem({
    required this.product,
    required this.shoppingType,
    this.cartQuantity = 1,
    this.selectedVariant,
  });

  /// Unique key for this cart item (product ID + variant combo)
  String get cartKey {
    if (selectedVariant == null || selectedVariant!.isEmpty) return product.id;
    final sortedKeys = selectedVariant!.keys.toList()..sort();
    final variantStr = sortedKeys.map((k) => '$k:${selectedVariant![k]}').join('|');
    return '${product.id}__$variantStr';
  }

  /// The effective price for this item (variant price or base price)
  double get effectivePrice {
    if (selectedVariant != null && product.isVariable) {
      return product.getVariantPrice(selectedVariant!);
    }
    return product.price;
  }

  /// The effective stock for this item (variant quantity or base quantity)
  int get effectiveStock {
    if (selectedVariant != null && product.isVariable) {
      return product.getVariantQuantity(selectedVariant!);
    }
    return product.quantity;
  }

  /// Total price for this cart line (unit price × quantity)
  double get lineTotal => effectivePrice * cartQuantity;

  /// Human-readable variant label
  String get variantLabel {
    if (selectedVariant == null || selectedVariant!.isEmpty) return '';
    return selectedVariant!.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  }
}
