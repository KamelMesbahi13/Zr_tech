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
  bool addToCart(ProductModel product) {
    final existing = getCartItem(product.id);

    if (existing != null) {
      // Already in cart — try to increment
      if (existing.cartQuantity >= product.quantity) {
        return false; // stock limit reached
      }
      existing.cartQuantity++;
    } else {
      // Not in cart yet — add with qty 1
      if (product.quantity < 1) return false; // out of stock
      _items.add(CartItem(product: product));
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
  /// Removes the item if quantity drops to 0.
  void decreaseQuantity(String productId) {
    final item = getCartItem(productId);
    if (item == null) return;

    if (item.cartQuantity <= 1) {
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
