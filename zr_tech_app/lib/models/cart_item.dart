import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final String shoppingType; // 'gros' or 'detail'
  int cartQuantity;

  CartItem({
    required this.product,
    required this.shoppingType,
    this.cartQuantity = 1,
  });

  /// Total price for this cart line (unit price × quantity)
  double get lineTotal => product.price * cartQuantity;
}
