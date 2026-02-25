import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../theme/responsive_wrapper.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _hasSeeded = false;
  String _shoppingType = 'gros';
  String _categoryId = '';
  String _categoryName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, String>) {
      _shoppingType = args['shoppingType'] ?? 'gros';
      _categoryId = args['categoryId'] ?? '';
      _categoryName = args['categoryName'] ?? '';
    }
    if (!_hasSeeded) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      var products = await _productService.getProducts(_shoppingType, _categoryId).timeout(const Duration(seconds: 10));

      // If no products exist, seed sample data first
      if (products.isEmpty && !_hasSeeded) {
        _hasSeeded = true;
        await _productService.seedProducts();
        products = await _productService.getProducts(_shoppingType, _categoryId).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (!mounted) return;
      setState(() {
        _products = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحميل المنتجات، تأكد من اتصالك بالأنترنت.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImageWidget(String imageStr, {BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: fit, width: double.infinity,
            errorBuilder: (_, __, ___) => _imagePlaceholder());
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(imageStr, fit: fit, width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Icon(Icons.image_outlined, color: const Color(0xFFBBBBBB), size: Responsive.sp(40)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
        body: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: Responsive.sp(260),
                height: Responsive.sp(260),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: Responsive.sp(200),
                height: Responsive.sp(200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(alpha: 0.04),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, Responsive.sp(16), hPad, Responsive.sp(8)),
                        child: Row(
                          children: [
                            // Title (RTL: starts from right)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _categoryName,
                                    style: TextStyle(
                                      color: const Color(0xFF1A1A2E),
                                      fontSize: Responsive.fp(22),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.sp(2)),
                                  Text(
                                    '${_products.length} منتج',
                                    style: TextStyle(
                                      color: const Color(0xFF888899),
                                      fontSize: Responsive.fp(13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Back button
                            Container(
                              width: Responsive.sp(40),
                              height: Responsive.sp(40),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF0F2F5),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.arrow_forward, color: const Color(0xFF1A1A2E), size: Responsive.sp(20)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.sp(8)),
                      // Products Grid
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              )
                            : _products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined,
                                            color: const Color(0xFFBBBBCC), size: Responsive.sp(56)),
                                        SizedBox(height: Responsive.sp(16)),
                                        Text(
                                          'لا توجد منتجات في هذه الفئة',
                                          style: TextStyle(
                                            color: const Color(0xFF666677),
                                            fontSize: Responsive.fp(16),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.sp(8)),
                                        Text(
                                          'ستتم إضافة المنتجات قريباً',
                                          style: TextStyle(
                                            color: const Color(0xFF999AAA),
                                            fontSize: Responsive.fp(13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth;
                                      final crossAxisCount = width > 900 ? 5 : width > 700 ? 4 : width > 500 ? 3 : 2;
                                      return GridView.builder(
                                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(8)),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: Responsive.sp(14),
                                          mainAxisSpacing: Responsive.sp(14),
                                          childAspectRatio: 0.65,
                                        ),
                                        itemCount: _products.length,
                                        itemBuilder: (context, index) {
                                          final product = _products[index];
                                          return _buildProductCard(product);
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product,
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with stock badge
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: product.image.isNotEmpty
                      ? _buildImageWidget(product.image)
                      : _imagePlaceholder(),
                ),
                // Stock badge
                Positioned(
                  top: Responsive.sp(8),
                  left: Responsive.sp(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.sp(8), vertical: Responsive.sp(4)),
                    decoration: BoxDecoration(
                      color: product.isAvailable
                          ? Colors.green.withValues(alpha: 0.9)
                          : Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.isAvailable
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: Colors.white,
                          size: Responsive.sp(12),
                        ),
                        SizedBox(width: Responsive.sp(3)),
                        Text(
                          product.isAvailable ? 'متوفر' : 'غير متوفر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fp(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product info
          Padding(
            padding: EdgeInsets.fromLTRB(Responsive.sp(10), Responsive.sp(8), Responsive.sp(10), Responsive.sp(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    color: const Color(0xFF1A1A2E),
                    fontSize: Responsive.fp(12),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.sp(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.sp(6), vertical: Responsive.sp(3)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${product.price.toStringAsFixed(0)} DA',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: Responsive.fp(13),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ),
                SizedBox(height: Responsive.sp(8)),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/product-detail',
                          arguments: product,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: Responsive.sp(8)),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'عرض المنتج',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fp(11),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
