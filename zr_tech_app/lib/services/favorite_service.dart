import 'package:firebase_database/firebase_database.dart';

class FavoriteService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Toggle favorite for a product. Returns the new favorited state.
  Future<bool> toggleFavorite({
    required String userId,
    required String productId,
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
  }) async {
    final favRef = _dbRef.child('favorites').child(userId).child(productId);
    final snapshot = await favRef.get();
    final wasFavorited = snapshot.exists && snapshot.value == true;

    final countRef = _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .child('favorites_count');

    if (wasFavorited) {
      // Remove favorite
      await favRef.remove();
      // Decrement count with transaction
      await countRef.runTransaction((value) {
        final current = (value as int?) ?? 0;
        return Transaction.success(current > 0 ? current - 1 : 0);
      });
      return false;
    } else {
      // Add favorite
      await favRef.set(true);
      // Increment count with transaction
      await countRef.runTransaction((value) {
        final current = (value as int?) ?? 0;
        return Transaction.success(current + 1);
      });
      return true;
    }
  }

  /// Check if a product is favorited by the user.
  Future<bool> isFavorited(String userId, String productId) async {
    final snapshot =
        await _dbRef.child('favorites').child(userId).child(productId).get();
    return snapshot.exists && snapshot.value == true;
  }

  /// Get the favorites count for a product.
  Future<int> getFavoritesCount({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String productId,
  }) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .child('favorites_count')
        .get();
    return (snapshot.value as int?) ?? 0;
  }

  /// Stream of whether the current user has favorited a product.
  Stream<bool> listenToFavorite(String userId, String productId) {
    return _dbRef
        .child('favorites')
        .child(userId)
        .child(productId)
        .onValue
        .map((event) => event.snapshot.exists && event.snapshot.value == true);
  }

  /// Stream of favorites count for a product.
  Stream<int> listenToFavoritesCount({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String productId,
  }) {
    return _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .child('favorites_count')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }

  /// Get a map of all favorited product IDs for a user (for batch loading).
  Future<Map<String, bool>> getUserFavorites(String userId) async {
    final snapshot = await _dbRef.child('favorites').child(userId).get();
    if (!snapshot.exists || snapshot.value == null) return {};
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.map((key, value) => MapEntry(key, value == true));
  }

  /// Listen to all favorites for a user (for batch realtime updates).
  Stream<Map<String, bool>> listenToUserFavorites(String userId) {
    return _dbRef.child('favorites').child(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.map((key, value) => MapEntry(key, value == true));
    });
  }
}
