import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int cartQuantity;

  CartItem({
    required this.product,
    this.cartQuantity = 1,
  });

  /// Total price for this cart line (unit price × quantity)
  double get lineTotal => product.price * cartQuantity;
}
