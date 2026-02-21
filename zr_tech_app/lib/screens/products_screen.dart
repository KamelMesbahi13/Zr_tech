import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

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
      var products = await _productService.getProducts(_shoppingType, _categoryId);

      // If no products exist, seed sample data first
      if (products.isEmpty && !_hasSeeded) {
        _hasSeeded = true;
        await _productService.seedProducts();
        products = await _productService.getProducts(_shoppingType, _categoryId);
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
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textSlate500, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_products.length} منتج',
                            style: const TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                                      color: AppColors.textSlate500, size: 56),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد منتجات في هذه الفئة',
                                    style: TextStyle(
                                      color: AppColors.textSlate400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'ستتم إضافة المنتجات قريباً',
                                    style: TextStyle(
                                      color: AppColors.textSlate500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                // Responsive: more columns on wider screens
                                final crossAxisCount = width > 900 ? 4 : width > 600 ? 3 : 2;
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
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
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with stock badge
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Product image
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: product.image.isNotEmpty
                      ? _buildImageWidget(product.image)
                      : _imagePlaceholder(),
                ),
                // Stock badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: product.isAvailable
                          ? Colors.green.withValues(alpha: 0.85)
                          : Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
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
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.isAvailable ? 'متوفر' : 'غير متوفر',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${product.price.toStringAsFixed(0)} DA',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // View product button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'عرض المنتج',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_back, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
