import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';

class ProductService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Fetch products for a specific category under a shopping type.
  Future<List<ProductModel>> getProducts(String shoppingType, String categoryId) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final products = <ProductModel>[];

    data.forEach((key, value) {
      products.add(
        ProductModel.fromMap(key, categoryId, Map<String, dynamic>.from(value as Map)),
      );
    });

    return products;
  }

  /// Fetch ALL products across all categories for a shopping type.
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

    categoriesData.forEach((categoryId, categoryProducts) {
      if (categoryProducts is Map) {
        final productsMap = Map<String, dynamic>.from(categoryProducts);
        productsMap.forEach((productId, productData) {
          if (productData is Map) {
            products.add(
              ProductModel.fromMap(
                productId,
                categoryId,
                Map<String, dynamic>.from(productData),
              ),
            );
          }
        });
      }
    });

    return products;
  }

  /// Generate the next product ID (prod_XXX format) for a category.
  Future<String> _getNextProductId(String shoppingType, String categoryId) async {
    final snapshot = await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
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

  /// Add a new product under a specific shopping type and category.
  Future<void> addProduct({
    required String shoppingType,
    required String categoryId,
    required String name,
    required String image,
    required double price,
    required String description,
    required bool isAvailable,
  }) async {
    final prodId = await _getNextProductId(shoppingType, categoryId);
    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(prodId)
        .set({
      'name': name,
      'image': image,
      'price': price,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Update an existing product.
  Future<void> updateProduct({
    required String shoppingType,
    required String categoryId,
    required String productId,
    required String name,
    required String image,
    required double price,
    required String description,
    required bool isAvailable,
  }) async {
    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(productId)
        .update({
      'name': name,
      'image': image,
      'price': price,
      'description': description,
      'isAvailable': isAvailable,
    });
  }

  /// Delete a product.
  Future<void> deleteProduct({
    required String shoppingType,
    required String categoryId,
    required String productId,
  }) async {
    await _dbRef
        .child('products')
        .child(shoppingType)
        .child(categoryId)
        .child(productId)
        .remove();
  }

  /// Seed sample products for demo purposes.
  /// Call once to populate the database with sample data.
  Future<void> seedProducts() async {
    final sampleProducts = {
      'cat_001': [
        {'name': 'كابل USB-C سريع الشحن', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB-pnanfgsRJ5BIbYazJJOKbNOnNrsxUyPwrl-w2C8SAu_Bk_ItGS3l5l1S1Io65YAnHQKJAlAEsVrZB4zrerg7qGOeBciMA-6wuPL2JEZmgTD8fQsuHPWyORqK-5nkKFEuPmnapCdIvXNGF0npLvRZek4pQ19GRJw4Pv15gkhClKoumDffuo2Fy3IIpxjCTfcpF8_ENb2yvk6G8hidRR_LZa0eKr2sJv4f_8fr-rfh8a0fC3ucYbe6mtpeXxPHRYwl-5A0bbuNSPa4', 'price': 350.0, 'isAvailable': true, 'description': 'كابل USB-C عالي الجودة يدعم الشحن السريع بقوة 65 واط. متوافق مع جميع الأجهزة الحديثة.'},
        {'name': 'كابل Lightning أصلي', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB-pnanfgsRJ5BIbYazJJOKbNOnNrsxUyPwrl-w2C8SAu_Bk_ItGS3l5l1S1Io65YAnHQKJAlAEsVrZB4zrerg7qGOeBciMA-6wuPL2JEZmgTD8fQsuHPWyORqK-5nkKFEuPmnapCdIvXNGF0npLvRZek4pQ19GRJw4Pv15gkhClKoumDffuo2Fy3IIpxjCTfcpF8_ENb2yvk6G8hidRR_LZa0eKr2sJv4f_8fr-rfh8a0fC3ucYbe6mtpeXxPHRYwl-5A0bbuNSPa4', 'price': 500.0, 'isAvailable': true, 'description': 'كابل Lightning معتمد من Apple. طول 1.5 متر مع حماية من التلف.'},
        {'name': 'كابل HDMI 4K', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB-pnanfgsRJ5BIbYazJJOKbNOnNrsxUyPwrl-w2C8SAu_Bk_ItGS3l5l1S1Io65YAnHQKJAlAEsVrZB4zrerg7qGOeBciMA-6wuPL2JEZmgTD8fQsuHPWyORqK-5nkKFEuPmnapCdIvXNGF0npLvRZek4pQ19GRJw4Pv15gkhClKoumDffuo2Fy3IIpxjCTfcpF8_ENb2yvk6G8hidRR_LZa0eKr2sJv4f_8fr-rfh8a0fC3ucYbe6mtpeXxPHRYwl-5A0bbuNSPa4', 'price': 800.0, 'isAvailable': false, 'description': 'كابل HDMI 2.1 يدعم دقة 4K@120Hz. مثالي للألعاب والعرض.'},
      ],
      'cat_002': [
        {'name': 'شاحن سريع 65W', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeNiB1DjysNW3AJGscjFY16A8Yp5nw67mOVa3TtD1aK6DJ3-6-duUC1addJ-0WGP-6FzHglbzZPPH9XPPqhYdUgHIA45dxFxamMMJhTY4GU7AU-YPmas_m--mi1MY8fvQU9AWVxO0BdYki_ewaxoM4S56TtHJWt6Az1l-LIB-tEUUBCuhRO20uXlsJmaMO0CZWhi89qz-LceQxmQdfbzhHh2R56FLwyGVrgWkVGW2IkFw9W1tTZhZSs321UtqWEiHKYgzN3iP71kBz', 'price': 1200.0, 'isAvailable': true, 'description': 'شاحن GaN سريع بقوة 65 واط مع منفذين USB-C ومنفذ USB-A.'},
        {'name': 'شاحن لاسلكي MagSafe', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeNiB1DjysNW3AJGscjFY16A8Yp5nw67mOVa3TtD1aK6DJ3-6-duUC1addJ-0WGP-6FzHglbzZPPH9XPPqhYdUgHIA45dxFxamMMJhTY4GU7AU-YPmas_m--mi1MY8fvQU9AWVxO0BdYki_ewaxoM4S56TtHJWt6Az1l-LIB-tEUUBCuhRO20uXlsJmaMO0CZWhi89qz-LceQxmQdfbzhHh2R56FLwyGVrgWkVGW2IkFw9W1tTZhZSs321UtqWEiHKYgzN3iP71kBz', 'price': 1800.0, 'isAvailable': true, 'description': 'قاعدة شحن لاسلكي متوافقة مع MagSafe. شحن سريع 15 واط.'},
        {'name': 'شاحن سيارة 30W', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeNiB1DjysNW3AJGscjFY16A8Yp5nw67mOVa3TtD1aK6DJ3-6-duUC1addJ-0WGP-6FzHglbzZPPH9XPPqhYdUgHIA45dxFxamMMJhTY4GU7AU-YPmas_m--mi1MY8fvQU9AWVxO0BdYki_ewaxoM4S56TtHJWt6Az1l-LIB-tEUUBCuhRO20uXlsJmaMO0CZWhi89qz-LceQxmQdfbzhHh2R56FLwyGVrgWkVGW2IkFw9W1tTZhZSs321UtqWEiHKYgzN3iP71kBz', 'price': 650.0, 'isAvailable': false, 'description': 'شاحن سيارة مزدوج المنافذ بقوة 30 واط. تصميم صغير ومتين.'},
      ],
      'cat_003': [
        {'name': 'سماعات بلوتوث لاسلكية', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkgTHrVRzR4sHh38G57yo3ykt_uCkWhnmqWQ5AldNRJ7w3grsegAKGCrY2VP1G7QfC_rfS2EV_9eL91wpVnvTAA1gRsUh5oaTFXj-JFnF6-6yJJ9-vB2M3gKu-X0Gvzr5rFRzYITcEs2dsx7c8g0CAdDa8pSb5H23sDrpewfq9PtJ1EjMwnytewG2lOCAHXI8rkXWCPhmCw4_Yh5A447Jcw4tS1Wb1eVYTJIU2tGgV5oW0p9EbL9eQdo-wFvzBc5REoehQjVk9hGc4', 'price': 2500.0, 'isAvailable': true, 'description': 'سماعات TWS بجودة صوت عالية مع إلغاء الضوضاء النشط. بطارية تدوم 8 ساعات.'},
        {'name': 'سماعات رأس احترافية', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkgTHrVRzR4sHh38G57yo3ykt_uCkWhnmqWQ5AldNRJ7w3grsegAKGCrY2VP1G7QfC_rfS2EV_9eL91wpVnvTAA1gRsUh5oaTFXj-JFnF6-6yJJ9-vB2M3gKu-X0Gvzr5rFRzYITcEs2dsx7c8g0CAdDa8pSb5H23sDrpewfq9PtJ1EjMwnytewG2lOCAHXI8rkXWCPhmCw4_Yh5A447Jcw4tS1Wb1eVYTJIU2tGgV5oW0p9EbL9eQdo-wFvzBc5REoehQjVk9hGc4', 'price': 4500.0, 'isAvailable': true, 'description': 'سماعات رأس لاسلكية مع ميكروفون مدمج. مثالية للألعاب والمكالمات.'},
        {'name': 'سماعات سلكية HiFi', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkgTHrVRzR4sHh38G57yo3ykt_uCkWhnmqWQ5AldNRJ7w3grsegAKGCrY2VP1G7QfC_rfS2EV_9eL91wpVnvTAA1gRsUh5oaTFXj-JFnF6-6yJJ9-vB2M3gKu-X0Gvzr5rFRzYITcEs2dsx7c8g0CAdDa8pSb5H23sDrpewfq9PtJ1EjMwnytewG2lOCAHXI8rkXWCPhmCw4_Yh5A447Jcw4tS1Wb1eVYTJIU2tGgV5oW0p9EbL9eQdo-wFvzBc5REoehQjVk9hGc4', 'price': 1200.0, 'isAvailable': false, 'description': 'سماعات سلكية بجودة HiFi مع تحكم بالصوت. متوافقة مع جميع الأجهزة.'},
      ],
    };

    for (final type in ['gros', 'detail']) {
      for (final entry in sampleProducts.entries) {
        final catId = entry.key;
        final products = entry.value;
        for (int i = 0; i < products.length; i++) {
          final prodId = 'prod_${(i + 1).toString().padLeft(3, '0')}';
          final productData = Map<String, dynamic>.from(products[i]);
          productData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
          await _dbRef
              .child('products')
              .child(type)
              .child(catId)
              .child(prodId)
              .set(productData);
        }
      }
    }
  }
}
