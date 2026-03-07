import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// Unmodifiable view of cart items
  List<CartItem> get items => List.unmodifiable(_items);

  /// Total number of individual items in the cart
  int get totalItems =>
      _items.fold<int>(0, (sum, item) => sum + item.cartQuantity);

  /// Grand total price
  double get totalPrice =>
      _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  /// Whether a product is already in the cart (by cartKey)
  bool isInCart(String productId, {Map<String, String>? variant}) {
    final key = _buildCartKey(productId, variant);
    return _items.any((item) => item.cartKey == key);
  }

  /// Get the cart item for a product + variant (or null)
  CartItem? getCartItem(String productId, {Map<String, String>? variant}) {
    final key = _buildCartKey(productId, variant);
    try {
      return _items.firstWhere((item) => item.cartKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Build a cart key from product ID and optional variant
  String _buildCartKey(String productId, Map<String, String>? variant) {
    if (variant == null || variant.isEmpty) return productId;
    final sortedKeys = variant.keys.toList()..sort();
    final variantStr = sortedKeys.map((k) => '$k:${variant[k]}').join('|');
    return '${productId}__$variantStr';
  }

  /// Add a product to the cart.
  /// Returns `true` if added/incremented successfully,
  /// `false` if the stock limit has been reached.
  bool addToCart(ProductModel product, {
    required String shoppingType,
    Map<String, String>? selectedVariant,
  }) {
    final existing = getCartItem(product.id, variant: selectedVariant);

    // Determine the effective stock limit
    final stockLimit = (selectedVariant != null && product.isVariable)
        ? product.getVariantQuantity(selectedVariant)
        : product.quantity;

    if (existing != null) {
      // Already in cart — try to increment
      if (existing.cartQuantity >= stockLimit) {
        return false; // stock limit reached
      }
      existing.cartQuantity++;
    } else {
      // Not in cart yet — add with appropriate starting quantity
      final startQty = shoppingType == 'gros' ? product.minQuantity : 1;
      if (stockLimit < startQty) return false; // not enough stock
      _items.add(CartItem(
        product: product,
        shoppingType: shoppingType,
        cartQuantity: startQty,
        selectedVariant: selectedVariant,
      ));
    }

    notifyListeners();
    return true;
  }

  /// Remove a product entirely from the cart
  void removeFromCart(String productId, {Map<String, String>? variant}) {
    final key = _buildCartKey(productId, variant);
    _items.removeWhere((item) => item.cartKey == key);
    notifyListeners();
  }

  /// Increase quantity by 1 (respects stock limit).
  /// Returns `false` if already at max.
  bool increaseQuantity(String productId, {Map<String, String>? variant}) {
    final item = getCartItem(productId, variant: variant);
    if (item == null) return false;

    if (item.cartQuantity >= item.effectiveStock) {
      return false; // stock limit
    }

    item.cartQuantity++;
    notifyListeners();
    return true;
  }

  /// Decrease quantity by 1.
  /// For gros items, removes if quantity drops below minQuantity.
  /// For detail items, removes if quantity drops to 0.
  void decreaseQuantity(String productId, {Map<String, String>? variant}) {
    final item = getCartItem(productId, variant: variant);
    if (item == null) return;

    final minQty = item.shoppingType == 'gros' ? item.product.minQuantity : 1;
    if (item.cartQuantity <= minQty) {
      removeFromCart(productId, variant: variant);
    } else {
      item.cartQuantity--;
      notifyListeners();
    }
  }

  /// Clear the entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
