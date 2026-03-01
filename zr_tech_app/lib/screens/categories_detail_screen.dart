import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../models/category_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_drawer.dart';
import '../theme/responsive_wrapper.dart';

class CategoriesDetailScreen extends StatefulWidget {
  const CategoriesDetailScreen({super.key});
  @override
  State<CategoriesDetailScreen> createState() => _CategoriesDetailScreenState();
}

class _CategoriesDetailScreenState extends State<CategoriesDetailScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  Set<String> _categoriesWithNewProducts = {};
  bool _isLoading = true;
  bool _hasSeeded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    const maxRetries = 2;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        var categories = await _categoryService
            .getCategories('detail')
            .timeout(const Duration(seconds: 15));

        // If no categories exist, seed them first
        if (categories.isEmpty && !_hasSeeded) {
          _hasSeeded = true;
          await _categoryService.seedCategories();
          categories = await _categoryService
              .getCategories('detail')
              .timeout(const Duration(seconds: 15));
        }

        if (!mounted) return;
        setState(() {
          _categories = categories;
          _filteredCategories = categories;
          _isLoading = false;
        });
        _checkForNewProducts();
        return; // Success, exit the retry loop
      } catch (e) {
        if (attempt < maxRetries) {
          // Wait briefly before retrying
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء تحميل الفئات، تأكد من اتصالك بالأنترنت.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where(
              (cat) => cat.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _checkForNewProducts() async {
    try {
      final allProducts = await _productService.getAllProducts('detail').timeout(const Duration(seconds: 10));
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final newCatIds = <String>{};
      for (final product in allProducts) {
        if (product.createdAt > sevenDaysAgo) {
          newCatIds.add(product.categoryId);
        }
      }
      if (!mounted) return;
      setState(() {
        _categoriesWithNewProducts = newCatIds;
      });
    } catch (_) {
      // Silently fail — badge is a nice-to-have
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, Responsive.sp(24), hPad, Responsive.sp(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: Responsive.sp(28),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'الفئات - بالتجزئة',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.fp(22),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/shopping-type',
                        ),
                        icon: Icon(
                          Icons.arrow_forward,
                          color: AppColors.textPrimary,
                          size: Responsive.sp(24),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterCategories,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.fp(14),
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث عن فئات...',
                      hintStyle: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                        size: Responsive.sp(22),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textMuted,
                                size: Responsive.sp(20),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterCategories('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Responsive.sp(16),
                        vertical: Responsive.sp(14),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.sp(16)),
                // Categories Grid
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _filteredCategories.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: Responsive.fp(16),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // Adaptive sizing based on screen width
                            final double maxExtent;
                            final double spacing;
                            final double gridHPad;
                            if (width < 400) {
                              maxExtent = 100;
                              spacing = 12;
                              gridHPad = 12;
                            } else if (width < 600) {
                              maxExtent = 120;
                              spacing = 14;
                              gridHPad = 16;
                            } else if (width < 800) {
                              maxExtent = 140;
                              spacing = 16;
                              gridHPad = 20;
                            } else {
                              maxExtent = 160;
                              spacing = 18;
                              gridHPad = 24;
                            }
                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: gridHPad,
                                vertical: Responsive.sp(16),
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: maxExtent,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = _filteredCategories[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/subcategories',
                                      arguments: {
                                        'shoppingType': 'detail',
                                        'categoryId': cat.id,
                                        'categoryName': cat.name,
                                      },
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.surfaceDark,
                                              border: Border.all(
                                                color: AppColors.borderSubtle,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.06,
                                                  ),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: ClipOval(
                                                    child: Image.network(
                                                      cat.image,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder: (c, e, s) => Container(
                                                        color: AppColors.surfaceDark,
                                                        child: Icon(
                                                          Icons.image,
                                                          color: AppColors.textSlate500,
                                                          size: Responsive.sp(28),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_categoriesWithNewProducts.contains(cat.id))
                                                  Positioned(
                                                    top: Responsive.sp(2),
                                                    right: Responsive.sp(2),
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: Responsive.sp(5), vertical: Responsive.sp(2)),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.auto_awesome,
                                                            color: Colors.white,
                                                            size: Responsive.sp(9),
                                                          ),
                                                          SizedBox(width: Responsive.sp(2)),
                                                          Text(
                                                            'جديد',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: Responsive.fp(8),
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
                                        ),
                                      ),
                                      SizedBox(height: Responsive.sp(6)),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: Responsive.fp(11),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
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
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<CartProvider>(
                  builder: (context, cart, _) => _navItem(
                    Icons.shopping_cart_outlined, 'السلة', 3,
                    badge: cart.totalItems > 0 ? cart.totalItems : null,
                  ),
                ),
                _navItem(Icons.favorite_outline, 'المفضلة', 2),
                _navItem(Icons.category, 'الفئات', 1, isActive: true),
                _navItem(Icons.home_outlined, 'الرئيسية', 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    bool isActive = false,
    int? badge,
  }) {
    final color = isActive ? AppColors.primary : AppColors.textSlate400;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/shopping-type');
            break;
          case 1:
            // Already on categories
            break;
          case 2:
            Navigator.pushNamed(context, '/favorites');
            break;
          case 3:
            showCartDrawer(context);
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: Responsive.sp(24)),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    width: Responsive.sp(14),
                    height: Responsive.sp(14),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceDark,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fp(8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.sp(4)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: Responsive.fp(10),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
