import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/subcategory_service.dart';
import '../services/product_service.dart';
import '../models/subcategory_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_drawer.dart';
import '../theme/responsive_wrapper.dart';

class SubcategoriesScreen extends StatefulWidget {
  const SubcategoriesScreen({super.key});
  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final SubcategoryService _subcategoryService = SubcategoryService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<SubcategoryModel> _subcategories = [];
  List<SubcategoryModel> _filteredSubcategories = [];
  Set<String> _subcategoriesWithNewProducts = {};
  bool _isLoading = true;
  String _shoppingType = 'gros';
  String _categoryId = '';
  String _categoryName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, String>) {
      final newType = args['shoppingType'] ?? 'gros';
      final newCatId = args['categoryId'] ?? '';
      final newCatName = args['categoryName'] ?? '';
      if (newCatId != _categoryId || newType != _shoppingType) {
        _shoppingType = newType;
        _categoryId = newCatId;
        _categoryName = newCatName;
        _loadSubcategories();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubcategories() async {
    setState(() => _isLoading = true);

    const maxRetries = 2;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final subcategories = await _subcategoryService
            .getSubcategories(_shoppingType, _categoryId)
            .timeout(const Duration(seconds: 15));

        if (!mounted) return;
        setState(() {
          _subcategories = subcategories;
          _filteredSubcategories = subcategories;
          _isLoading = false;
        });
        _checkForNewProducts();
        return;
      } catch (e) {
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحميل الأقسام الفرعية، تأكد من اتصالك بالأنترنت.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterSubcategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubcategories = _subcategories;
      } else {
        _filteredSubcategories = _subcategories
            .where((subcat) => subcat.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _checkForNewProducts() async {
    try {
      final allProducts = await _productService
          .getAllProducts(_shoppingType)
          .timeout(const Duration(seconds: 10));
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final newSubcatIds = <String>{};
      for (final product in allProducts) {
        if (product.categoryId == _categoryId &&
            product.createdAt > sevenDaysAgo) {
          newSubcatIds.add(product.subcategoryId);
        }
      }
      if (!mounted) return;
      setState(() {
        _subcategoriesWithNewProducts = newSubcatIds;
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
                          _categoryName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.fp(22),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
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
                    onChanged: _filterSubcategories,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.fp(14),
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث عن أقسام فرعية...',
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
                                _filterSubcategories('');
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
                // Subcategories Grid
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _filteredSubcategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, color: AppColors.textSlate500, size: Responsive.sp(56)),
                              SizedBox(height: Responsive.sp(16)),
                              Text(
                                _subcategories.isEmpty
                                    ? 'لا توجد أقسام فرعية في هذه الفئة'
                                    : 'لا توجد نتائج مطابقة',
                                style: TextStyle(
                                  color: AppColors.textSlate400,
                                  fontSize: Responsive.fp(16),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
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
                              itemCount: _filteredSubcategories.length,
                              itemBuilder: (context, index) {
                                final subcat = _filteredSubcategories[index];
                                return _buildSubcategoryItem(subcat);
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
                _navItem(Icons.person_outline, 'حسابي', 3),
                Consumer<CartProvider>(
                  builder: (context, cart, _) => _navItem(
                    Icons.shopping_cart_outlined, 'السلة', 2,
                    badge: cart.totalItems > 0 ? cart.totalItems : null,
                  ),
                ),
                _navItem(Icons.category, 'الفئات', 1),
                _navItem(Icons.home_outlined, 'الرئيسية', 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryItem(SubcategoryModel subcat) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/products',
          arguments: {
            'shoppingType': _shoppingType,
            'categoryId': _categoryId,
            'subcategoryId': subcat.id,
            'categoryName': subcat.name,
          },
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AspectRatio(
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
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipOval(
                      child: subcat.image.isNotEmpty
                          ? _buildImageWidget(subcat.image)
                          : Container(
                              color: AppColors.surfaceDark,
                              child: Icon(
                                Icons.category_outlined,
                                color: AppColors.textSlate500,
                                size: Responsive.sp(28),
                              ),
                            ),
                    ),
                  ),
                ),
                if (_subcategoriesWithNewProducts.contains(subcat.id))
                  PositionedDirectional(
                    top: Responsive.sp(2),
                    start: Responsive.sp(2),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.sp(5),
                        vertical: Responsive.sp(2),
                      ),
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
          SizedBox(height: Responsive.sp(6)),
          Text(
            subcat.name,
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
  }

  Widget _buildImageWidget(String imageStr) {
    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => _imagePlaceholder());
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(imageStr, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: Icon(
        Icons.image,
        color: AppColors.textSlate500,
        size: Responsive.sp(28),
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
            // Go back to the categories screen
            Navigator.pop(context);
            break;
          case 2:
            showCartDrawer(context);
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
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
                      border: Border.all(color: AppColors.surfaceDark, width: 1.5),
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
