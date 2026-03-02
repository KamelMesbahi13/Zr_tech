import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';

class ProductService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Fetch products for a specific subcategory under a category and shopping type.
  Future<List<ProductModel>> getProducts(String shoppingType, String categoryId, String subcategoryId) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final products = <ProductModel>[];

    data.forEach((key, value) {
      products.add(
        ProductModel.fromMap(key, categoryId, Map<String, dynamic>.from(value as Map), subcategoryId: subcategoryId),
      );
    });

    return products;
  }

  /// Fetch ALL products across all categories and subcategories for a shopping type.
  Future<List<ProductModel>> getAllProducts(String shoppingType) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final categoriesData = Map<String, dynamic>.from(snapshot.value as Map);
    final products = <ProductModel>[];

    categoriesData.forEach((categoryId, categoryData) {
      if (categoryData is Map) {
        final subcategoriesMap = Map<String, dynamic>.from(categoryData);
        subcategoriesMap.forEach((subcategoryId, subcatProducts) {
          if (subcatProducts is Map) {
            final productsMap = Map<String, dynamic>.from(subcatProducts);
            productsMap.forEach((productId, productData) {
              if (productData is Map) {
                products.add(
                  ProductModel.fromMap(
                    productId,
                    categoryId,
                    Map<String, dynamic>.from(productData),
                    subcategoryId: subcategoryId,
                  ),
                );
              }
            });
          }
        });
      }
    });

    return products;
  }

  /// Generate the next product ID (prod_XXX format) for a subcategory.
  Future<String> _getNextProductId(String shoppingType, String categoryId, String subcategoryId) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .get();

    int maxNum = 0;

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final key in data.keys) {
        final match = RegExp(r'prod_(\d+)').firstMatch(key);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }

    final nextNum = maxNum + 1;
    return 'prod_${nextNum.toString().padLeft(3, '0')}';
  }

  /// Add a new product under a specific shopping type, category, and subcategory. Admin only.
  Future<void> addProduct({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String name,
    required List<String> images,
    required double price,
    required String description,
    required int quantity,
    int minQuantity = 1,
    String? color,
    String? condition,
    String? box,
    String? conditionStatus,
    String? charger,
    String? headphones,
    String? warranty,
    double? detailMarketPrice,
    String? countryOfOrigin,
  }) async {
    await AuthService().requireAdmin();
    final prodId = await _getNextProductId(shoppingType, categoryId, subcategoryId);
    final data = <String, dynamic>{
      'name': name,
      'images': images,
      'price': price,
      'description': description,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (color != null) data['color'] = color;
    if (condition != null) data['condition'] = condition;
    if (box != null) data['box'] = box;
    if (conditionStatus != null) data['conditionStatus'] = conditionStatus;
    if (charger != null) data['charger'] = charger;
    if (headphones != null) data['headphones'] = headphones;
    if (warranty != null) data['warranty'] = warranty;
    if (detailMarketPrice != null) data['detailMarketPrice'] = detailMarketPrice;
    if (countryOfOrigin != null) data['countryOfOrigin'] = countryOfOrigin;

    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(prodId)
        .set(data);
  }

  /// Update an existing product. Admin only.
  Future<void> updateProduct({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String productId,
    required String name,
    required List<String> images,
    required double price,
    required String description,
    required int quantity,
    int minQuantity = 1,
    String? color,
    String? condition,
    String? box,
    String? conditionStatus,
    String? charger,
    String? headphones,
    String? warranty,
    double? detailMarketPrice,
    String? countryOfOrigin,
  }) async {
    await AuthService().requireAdmin();
    final data = <String, dynamic>{
      'name': name,
      'images': images,
      'price': price,
      'description': description,
      'quantity': quantity,
      'minQuantity': minQuantity,
    };
    if (color != null) data['color'] = color;
    if (condition != null) data['condition'] = condition;
    if (box != null) data['box'] = box;
    if (conditionStatus != null) data['conditionStatus'] = conditionStatus;
    if (charger != null) data['charger'] = charger;
    if (headphones != null) data['headphones'] = headphones;
    if (warranty != null) data['warranty'] = warranty;
    if (detailMarketPrice != null) data['detailMarketPrice'] = detailMarketPrice;
    if (countryOfOrigin != null) data['countryOfOrigin'] = countryOfOrigin;

    // Clear fields that were set to null (remove from DB)
    if (color == null) data['color'] = null;
    if (condition == null) data['condition'] = null;
    if (box == null) data['box'] = null;
    if (conditionStatus == null) data['conditionStatus'] = null;
    if (charger == null) data['charger'] = null;
    if (headphones == null) data['headphones'] = null;
    if (warranty == null) data['warranty'] = null;
    if (detailMarketPrice == null) data['detailMarketPrice'] = null;
    if (countryOfOrigin == null) data['countryOfOrigin'] = null;

    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .update(data);
  }

  /// Delete a product. Admin only.
  Future<void> deleteProduct({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String productId,
  }) async {
    await AuthService().requireAdmin();
    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .remove();
  }

  /// Decrease the quantity of a product after a purchase.
  /// The quantity will never go below 0.
  Future<void> decreaseQuantity({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String productId,
    required int amount,
  }) async {
    final ref = _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .child(productId)
        .child('quantity');

    final snapshot = await ref.get();
    final currentQty = (snapshot.value ?? 0) as int;
    final newQty = (currentQty - amount).clamp(0, currentQty);
    await ref.set(newQty);
  }
}
