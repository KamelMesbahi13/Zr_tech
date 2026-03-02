import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';

class OrderService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('orders');

  /// Place a new order: saves to Firebase and attempts to decrease product stock.
  Future<void> placeOrder(OrderModel order) async {
    // Generate order ID
    final orderId = _dbRef.push().key ?? DateTime.now().millisecondsSinceEpoch.toString();

    final orderData = order.toMap();
    orderData['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    // Save order
    await _dbRef.child(orderId).set(orderData);

    // Decrease product stock (best-effort — may fail if user is not authenticated)
    try {
      final productService = ProductService();
      await productService.decreaseQuantity(
        shoppingType: order.shoppingType,
        categoryId: order.categoryId,
        subcategoryId: order.subcategoryId,
        productId: order.productId,
        amount: order.quantity,
      );
    } catch (_) {
      // Stock update failed (e.g. permission denied for unauthenticated users).
      // Order was already saved successfully — admin can adjust stock manually.
    }
  }

  /// Fetch all orders (for admin panel). Admin only.
  Future<List<OrderModel>> getAllOrders() async {
    await AuthService().requireAdmin();
    final snapshot = await _dbRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final orders = <OrderModel>[];

    data.forEach((key, value) {
      if (value is Map) {
        orders.add(
          OrderModel.fromMap(key, Map<String, dynamic>.from(value)),
        );
      }
    });

    // Sort by createdAt descending (newest first)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Fetch orders for a specific user (for order tracking screen).
  /// Does NOT require admin auth — reads all orders and filters client-side.
  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    if (userId.isEmpty) return [];

    final snapshot = await _dbRef.orderByChild('userId').equalTo(userId).get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final orders = <OrderModel>[];

    data.forEach((key, value) {
      if (value is Map) {
        orders.add(
          OrderModel.fromMap(key, Map<String, dynamic>.from(value)),
        );
      }
    });

    // Sort by createdAt descending (newest first)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Update the status of an order. Admin only.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await AuthService().requireAdmin();
    await _dbRef.child(orderId).update({'status': newStatus});
  }

  /// Delete an order. Admin only.
  Future<void> deleteOrder(String orderId) async {
    await AuthService().requireAdmin();
    await _dbRef.child(orderId).remove();
  }
}
