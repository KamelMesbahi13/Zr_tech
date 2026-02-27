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

  /// Whether a product is already in the cart
  bool isInCart(String productId) =>
      _items.any((item) => item.product.id == productId);

  /// Get the cart item for a product (or null)
  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Add a product to the cart.
  /// Returns `true` if added/incremented successfully,
  /// `false` if the stock limit has been reached.
  bool addToCart(ProductModel product, {required String shoppingType}) {
    final existing = getCartItem(product.id);

    if (existing != null) {
      // Already in cart — try to increment
      if (existing.cartQuantity >= product.quantity) {
        return false; // stock limit reached
      }
      existing.cartQuantity++;
    } else {
      // Not in cart yet — add with appropriate starting quantity
      final startQty = shoppingType == 'gros' ? product.minQuantity : 1;
      if (product.quantity < startQty) return false; // not enough stock
      _items.add(CartItem(product: product, shoppingType: shoppingType, cartQuantity: startQty));
    }

    notifyListeners();
    return true;
  }

  /// Remove a product entirely from the cart
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Increase quantity by 1 (respects stock limit).
  /// Returns `false` if already at max.
  bool increaseQuantity(String productId) {
    final item = getCartItem(productId);
    if (item == null) return false;

    if (item.cartQuantity >= item.product.quantity) {
      return false; // stock limit
    }

    item.cartQuantity++;
    notifyListeners();
    return true;
  }

  /// Decrease quantity by 1.
  /// For gros items, removes if quantity drops below minQuantity.
  /// For detail items, removes if quantity drops to 0.
  void decreaseQuantity(String productId) {
    final item = getCartItem(productId);
    if (item == null) return;

    final minQty = item.shoppingType == 'gros' ? item.product.minQuantity : 1;
    if (item.cartQuantity <= minQty) {
      removeFromCart(productId);
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
