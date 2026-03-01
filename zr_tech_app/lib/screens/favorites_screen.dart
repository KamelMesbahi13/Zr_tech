import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../theme/responsive_wrapper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AuthService _authService = AuthService();
  final FavoriteService _favoriteService = FavoriteService();
  final ProductService _productService = ProductService();

  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = true;
  StreamSubscription? _favoritesSub;

  String? get _currentUserId => _authService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get all favorited product IDs
      final favMap = await _favoriteService.getUserFavorites(userId);
      final favProductIds = favMap.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();

      if (favProductIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteProducts = [];
            _isLoading = false;
          });
        }
        _setupStream(userId);
        return;
      }

      // Load products from both shopping types
      final allProducts = <ProductModel>[];
      for (final type in ['gros', 'detail']) {
        try {
          final products = await _productService
              .getAllProducts(type)
              .timeout(const Duration(seconds: 10));
          allProducts.addAll(products);
        } catch (_) {}
      }

      // Filter to only favorited products
      final favorites = allProducts
          .where((p) => favProductIds.contains(p.id))
          .toList();

      if (mounted) {
        setState(() {
          _favoriteProducts = favorites;
          _isLoading = false;
        });
      }

      _setupStream(userId);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _favoriteProducts = [];
          _isLoading = false;
        });
      }
    }
  }

  void _setupStream(String userId) {
    _favoritesSub?.cancel();
    _favoritesSub =
        _favoriteService.listenToUserFavorites(userId).listen((favMap) {
      // When favorites change, reload
      _reloadFromFavMap(favMap);
    });
  }

  Future<void> _reloadFromFavMap(Map<String, bool> favMap) async {
    final favProductIds =
        favMap.entries.where((e) => e.value).map((e) => e.key).toSet();

    if (favProductIds.isEmpty) {
      if (mounted) setState(() => _favoriteProducts = []);
      return;
    }

    try {
      final allProducts = <ProductModel>[];
      for (final type in ['gros', 'detail']) {
        try {
          final products = await _productService
              .getAllProducts(type)
              .timeout(const Duration(seconds: 10));
          allProducts.addAll(products);
        } catch (_) {}
      }

      final favorites =
          allProducts.where((p) => favProductIds.contains(p.id)).toList();

      if (mounted) setState(() => _favoriteProducts = favorites);
    } catch (_) {}
  }

  Future<void> _removeFavorite(ProductModel product) async {
    final userId = _currentUserId;
    if (userId == null) return;

    // Determine shopping type from route or default
    final shoppingType = 'gros'; // We'll try both types

    try {
      await _favoriteService.toggleFavorite(
        userId: userId,
        productId: product.id,
        shoppingType: shoppingType,
        categoryId: product.categoryId,
        subcategoryId: product.subcategoryId,
      );
      if (mounted) {
        setState(() {
          _favoriteProducts.removeWhere((p) => p.id == product.id);
        });
      }
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  Widget _buildImageWidget(String imageStr, {BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes,
            fit: fit,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _imagePlaceholder());
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(imageStr,
        fit: fit,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.textHint, size: Responsive.sp(40)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      hPad, Responsive.sp(16), hPad, Responsive.sp(8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المفضلة',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: Responsive.fp(22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Responsive.sp(2)),
                            Text(
                              '${_favoriteProducts.length} منتج',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: Responsive.fp(13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: Responsive.sp(40),
                        height: Responsive.sp(40),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceAlt,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_forward,
                              color: AppColors.textPrimary,
                              size: Responsive.sp(20)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.sp(8)),

                // Content
                Expanded(
                  child: _currentUserId == null
                      ? _buildLoginPrompt()
                      : _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            )
                          : _favoriteProducts.isEmpty
                              ? _buildEmptyState()
                              : _buildFavoritesList(hPad),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              color: AppColors.textHint, size: Responsive.sp(56)),
          SizedBox(height: Responsive.sp(16)),
          Text(
            'يرجى تسجيل الدخول لعرض المفضلة',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: Responsive.fp(16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.sp(16)),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login, size: 18),
            label: Text('تسجيل الدخول',
                style: TextStyle(fontSize: Responsive.fp(14))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: Responsive.sp(24), vertical: Responsive.sp(12)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              color: AppColors.textHint, size: Responsive.sp(56)),
          SizedBox(height: Responsive.sp(16)),
          Text(
            'لم تقم بإضافة أي منتج للمفضلة بعد',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: Responsive.fp(16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.sp(8)),
          Text(
            'اضغط على أيقونة القلب في أي منتج لإضافته هنا',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: Responsive.fp(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(double hPad) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount =
            width > 900 ? 5 : width > 700 ? 4 : width > 500 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: hPad, vertical: Responsive.sp(8)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Responsive.sp(14),
            mainAxisSpacing: Responsive.sp(14),
            childAspectRatio: 0.65,
          ),
          itemCount: _favoriteProducts.length,
          itemBuilder: (context, index) {
            final product = _favoriteProducts[index];
            return _buildFavoriteCard(product);
          },
        );
      },
    );
  }

  Widget _buildFavoriteCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: {'product': product, 'shoppingType': 'gros'},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
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
            // Image with remove favorite button
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
                  // Remove favorite button
                  Positioned(
                    top: Responsive.sp(8),
                    left: Responsive.sp(8),
                    child: GestureDetector(
                      onTap: () => _removeFavorite(product),
                      child: Container(
                        padding: EdgeInsets.all(Responsive.sp(6)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: AppColors.error,
                          size: Responsive.sp(18),
                        ),
                      ),
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: Responsive.sp(8),
                    right: Responsive.sp(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: Responsive.sp(8),
                          vertical: Responsive.sp(4)),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? AppColors.success.withValues(alpha: 0.9)
                            : AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isAvailable ? 'متوفر' : 'غير متوفر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fp(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.sp(10), Responsive.sp(8),
                  Responsive.sp(10), Responsive.sp(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.sp(6),
                        vertical: Responsive.sp(3)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
