import 'package:firebase_database/firebase_database.dart';
import '../models/subcategory_model.dart';
import '../services/auth_service.dart';

class SubcategoryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Fetch subcategories for a specific category under a shopping type.
  Future<List<SubcategoryModel>> getSubcategories(String shoppingType, String categoryId) async {
    final snapshot = await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .child(categoryId)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final subcategories = <SubcategoryModel>[];

    data.forEach((key, value) {
      subcategories.add(
        SubcategoryModel.fromMap(key, categoryId, Map<String, dynamic>.from(value as Map)),
      );
    });

    // Sort by order
    subcategories.sort((a, b) => a.order.compareTo(b.order));
    return subcategories;
  }

  /// Fetch all subcategories across all categories for a shopping type.
  Future<Map<String, List<SubcategoryModel>>> getAllSubcategories(String shoppingType) async {
    final snapshot = await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .get();

    final result = <String, List<SubcategoryModel>>{};

    if (!snapshot.exists || snapshot.value == null) {
      return result;
    }

    final categoriesData = Map<String, dynamic>.from(snapshot.value as Map);
    categoriesData.forEach((categoryId, subcatsData) {
      if (subcatsData is Map) {
        final subcatsMap = Map<String, dynamic>.from(subcatsData);
        final subcats = <SubcategoryModel>[];
        subcatsMap.forEach((subcatId, subcatData) {
          if (subcatData is Map) {
            subcats.add(
              SubcategoryModel.fromMap(
                subcatId,
                categoryId,
                Map<String, dynamic>.from(subcatData),
              ),
            );
          }
        });
        subcats.sort((a, b) => a.order.compareTo(b.order));
        result[categoryId] = subcats;
      }
    });

    return result;
  }

  /// Generate the next subcategory ID (subcat_XXX format).
  Future<String> _getNextSubcategoryId(String shoppingType, String categoryId) async {
    final snapshot = await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .child(categoryId)
        .get();

    int maxNum = 0;

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final key in data.keys) {
        final match = RegExp(r'subcat_(\d+)').firstMatch(key);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }

    final nextNum = maxNum + 1;
    return 'subcat_${nextNum.toString().padLeft(3, '0')}';
  }

  /// Add a new subcategory. Admin only.
  Future<void> addSubcategory({
    required String shoppingType,
    required String categoryId,
    required String name,
    required String image,
    required int order,
  }) async {
    await AuthService().requireAdmin();
    final subcatId = await _getNextSubcategoryId(shoppingType, categoryId);
    await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .child(categoryId)
        .child(subcatId)
        .set({
      'name': name,
      'image': image,
      'order': order,
    });
  }

  /// Update an existing subcategory. Admin only.
  Future<void> updateSubcategory({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
    required String name,
    required String image,
    required int order,
  }) async {
    await AuthService().requireAdmin();
    await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .update({
      'name': name,
      'image': image,
      'order': order,
    });
  }

  /// Delete a subcategory. Admin only.
  Future<void> deleteSubcategory({
    required String shoppingType,
    required String categoryId,
    required String subcategoryId,
  }) async {
    await AuthService().requireAdmin();
    await _dbRef
        .child('subcategories')
        .child(shoppingType)
        .child(categoryId)
        .child(subcategoryId)
        .remove();
  }
}
