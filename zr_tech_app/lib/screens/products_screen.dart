import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/user_note_service.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../theme/responsive_wrapper.dart';
import '../widgets/cart_drawer.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  final UserNoteService _userNoteService = UserNoteService();
  final AuthService _authService = AuthService();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _hasSeeded = false;
  String _shoppingType = 'gros';
  String _categoryId = '';
  String _subcategoryId = '';
  String _categoryName = '';
  String _selectedFilter = 'all';

  // State maps for favorites and notes
  Map<String, bool> _favoritesMap = {};
  Map<String, int> _favoritesCountMap = {};
  Map<String, int> _noteCountsMap = {};

  // Stream subscriptions
  StreamSubscription? _favoritesSub;
  StreamSubscription? _notesSub;

  String? get _currentUserId => _authService.currentUser?.uid;

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _shoppingType = (args['shoppingType'] ?? 'gros').toString();
      _categoryId = (args['categoryId'] ?? '').toString();
      _subcategoryId = (args['subcategoryId'] ?? '').toString();
      _categoryName = (args['categoryName'] ?? '').toString();
    }
    _didInit = true;
    _loadProducts();
    _setupUserStreams();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    _notesSub?.cancel();
    super.dispose();
  }

  void _setupUserStreams() {
    final userId = _currentUserId;
    if (userId == null) return;

    _favoritesSub?.cancel();
    _favoritesSub =
        _favoriteService.listenToUserFavorites(userId).listen((favs) {
      if (mounted) setState(() => _favoritesMap = favs);
    });

    _notesSub?.cancel();
    _notesSub = _userNoteService.listenToUserNoteCounts(userId).listen((counts) {
      if (mounted) setState(() => _noteCountsMap = counts);
    });
  }

  Future<void> _loadProducts() async {
    if (_categoryId.isEmpty || _subcategoryId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      var products = await _productService
          .getProducts(_shoppingType, _categoryId, _subcategoryId)
          .timeout(const Duration(seconds: 10));

      if (products.isEmpty && !_hasSeeded) {
        _hasSeeded = true;
      }

      // Load favorites counts
      final countsMap = <String, int>{};
      for (final p in products) {
        try {
          final count = await _favoriteService.getFavoritesCount(
            shoppingType: _shoppingType,
            categoryId: _categoryId,
            subcategoryId: _subcategoryId,
            productId: p.id,
          );
          countsMap[p.id] = count;
        } catch (_) {
          countsMap[p.id] = 0;
        }
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _favoritesCountMap = countsMap;
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
          content: Text(
              'حدث خطأ أثناء تحميل المنتجات، تأكد من اتصالك بالأنترنت.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isNewProduct(ProductModel product) {
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    return product.createdAt > sevenDaysAgo;
  }

  List<ProductModel> get _filteredProducts {
    if (_selectedFilter == 'new') {
      final sorted = List<ProductModel>.from(_products);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    }
    return _products;
  }

  // ── Auth check ─────────────────────────────────────────────────

  bool _requireAuth(String action) {
    if (_currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى تسجيل الدخول ل$action'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'تسجيل الدخول',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    );
    return false;
  }

  // ── Favorite toggle (optimistic) ───────────────────────────────

  Future<void> _toggleFavorite(ProductModel product) async {
    if (!_requireAuth('إضافة المفضلة')) return;
    final userId = _currentUserId!;

    // Optimistic update
    final wasFav = _favoritesMap[product.id] ?? false;
    final prevCount = _favoritesCountMap[product.id] ?? 0;
    setState(() {
      _favoritesMap[product.id] = !wasFav;
      _favoritesCountMap[product.id] =
          !wasFav ? prevCount + 1 : (prevCount > 0 ? prevCount - 1 : 0);
    });

    try {
      await _favoriteService.toggleFavorite(
        userId: userId,
        productId: product.id,
        shoppingType: _shoppingType,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _favoritesMap[product.id] = wasFav;
          _favoritesCountMap[product.id] = prevCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، حاول مرة أخرى'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Note bottom sheet (multi-comment) ───────────────────────────

  void _openNoteSheet(ProductModel product) {
    if (!_requireAuth('إضافة ملاحظة')) return;
    final userId = _currentUserId!;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              Responsive.sp(20),
              Responsive.sp(16),
              Responsive.sp(20),
              Responsive.sp(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.sp(12)),
                Text(
                  'ملاحظات — ${product.name}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fp(16),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: Responsive.sp(12)),
                // Existing notes list
                Flexible(
                  child: StreamBuilder<List<UserNote>>(
                    stream: _userNoteService.listenToProductNotes(userId, product.id),
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? [];
                      if (notes.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                          child: Center(
                            child: Text(
                              'لا توجد ملاحظات بعد',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: Responsive.fp(13),
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => SizedBox(height: Responsive.sp(8)),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Container(
                            padding: EdgeInsets.all(Responsive.sp(12)),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Delete button
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await _userNoteService.deleteNote(
                                        userId: userId,
                                        productId: product.id,
                                        noteId: note.id,
                                      );
                                    } catch (e) {
                                      debugPrint('Error deleting note: \$e');
                                    }
                                  },
                                  child: Icon(Icons.close,
                                      color: AppColors.error,
                                      size: Responsive.sp(16)),
                                ),
                                SizedBox(width: Responsive.sp(8)),
                                // Note text
                                Expanded(
                                  child: Text(
                                    note.text,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: Responsive.fp(13),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: Responsive.sp(12)),
                // Add new comment input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 2,
                        minLines: 1,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'أضف ملاحظة جديدة...',
                          hintStyle: TextStyle(
                              color: AppColors.textHint,
                              fontSize: Responsive.fp(13)),
                          filled: true,
                          fillColor: AppColors.surfaceInput,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Responsive.sp(12),
                            vertical: Responsive.sp(10),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.sp(8)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          try {
                            await _userNoteService.addNote(
                              userId: userId,
                              productId: product.id,
                              noteText: text,
                            );
                            controller.clear();
                            // Update local count
                            if (mounted) {
                              setState(() {
                                _noteCountsMap[product.id] =
                                    (_noteCountsMap[product.id] ?? 0) + 1;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error adding note: \$e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('حدث خطأ أثناء حفظ الملاحظة'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.send,
                            color: Colors.white, size: Responsive.sp(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Image helpers ──────────────────────────────────────────────

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

  // ── Filter chip ────────────────────────────────────────────────

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: Responsive.sp(16), vertical: Responsive.sp(10)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: Responsive.sp(16),
                color: isSelected ? Colors.white : AppColors.textMuted),
            SizedBox(width: Responsive.sp(6)),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: Responsive.fp(13),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;
    final displayProducts = _filteredProducts;

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
                      // Back button (appears on right in RTL)
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
                      SizedBox(width: Responsive.sp(12)),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _categoryName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: Responsive.fp(22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Responsive.sp(2)),
                            Text(
                              '${displayProducts.length} منتج',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: Responsive.fp(13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cart icon with badge (appears on left in RTL)
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return GestureDetector(
                            onTap: () => showCartDrawer(context),
                            child: Container(
                              width: Responsive.sp(40),
                              height: Responsive.sp(40),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceAlt,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: AppColors.textPrimary,
                                      size: Responsive.sp(20),
                                    ),
                                  ),
                                  if (cart.totalItems > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: Responsive.sp(18),
                                        height: Responsive.sp(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.surfaceAlt,
                                              width: 1.5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${cart.totalItems}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: Responsive.fp(9),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Filter chips
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: Responsive.sp(8)),
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all', Icons.apps_rounded),
                      SizedBox(width: Responsive.sp(10)),
                      _buildFilterChip(
                          'جديد', 'new', Icons.fiber_new_rounded),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.sp(4)),
                // Products Grid
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        )
                      : displayProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      color: AppColors.textHint,
                                      size: Responsive.sp(56)),
                                  SizedBox(height: Responsive.sp(16)),
                                  Text(
                                    'لا توجد منتجات في هذه الفئة',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: Responsive.fp(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.sp(8)),
                                  Text(
                                    'ستتم إضافة المنتجات قريباً',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: Responsive.fp(13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _buildProductsGrid(displayProducts, hPad),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Products Grid ──────────────────────────────────────────────

  Widget _buildProductsGrid(
      List<ProductModel> displayProducts, double hPad) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount =
            width > 700 ? 4 : width > 500 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: hPad, vertical: Responsive.sp(8)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Responsive.sp(14),
            mainAxisSpacing: Responsive.sp(14),
            childAspectRatio: 0.58,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }


  // ── Product Card ───────────────────────────────────────────────

  Widget _buildProductCard(ProductModel product) {
    final isFav = _favoritesMap[product.id] ?? false;
    final favCount = _favoritesCountMap[product.id] ?? 0;
    final noteCount = _noteCountsMap[product.id] ?? 0;

    return Container(
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
          // ── Image area with overlays ──
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: {
                    'product': product,
                    'shoppingType': _shoppingType,
                  },
                );
              },
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
                    top: Responsive.sp(8),
                    left: Responsive.sp(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: Responsive.sp(8),
                          vertical: Responsive.sp(4)),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? AppColors.success.withValues(alpha: 0.9)
                            : AppColors.error.withValues(alpha: 0.9),
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

                  // "New" badge
                  if (_isNewProduct(product))
                    Positioned(
                      top: Responsive.sp(8),
                      right: Responsive.sp(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.sp(8),
                            vertical: Responsive.sp(4)),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B35),
                              Color(0xFFFF8F00)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white,
                                size: Responsive.sp(11)),
                            SizedBox(width: Responsive.sp(3)),
                            Text(
                              'جديد',
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

                  // RIGHT side visually (Positioned left in RTL): Favorite + Note
                  Positioned(
                    left: Responsive.sp(6),
                    bottom: Responsive.sp(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconButton(
                          icon: isFav
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFav
                              ? AppColors.error
                              : AppColors.textMuted,
                          count: favCount,
                          onTap: () => _toggleFavorite(product),
                        ),
                        SizedBox(height: Responsive.sp(6)),
                        _buildIconButton(
                          icon: noteCount > 0
                              ? Icons.comment
                              : Icons.comment_outlined,
                          color: noteCount > 0
                              ? AppColors.primary
                              : AppColors.textMuted,
                          count: noteCount,
                          onTap: () => _openNoteSheet(product),
                        ),
                      ],
                    ),
                  ),

                  // LEFT side visually (Positioned right in RTL): Quantity controls
                  Positioned(
                    right: Responsive.sp(6),
                    bottom: Responsive.sp(8),
                    child: Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        final cartItem = cart.getCartItem(product.id);
                        final cartQty = cartItem?.cartQuantity ?? 0;
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: Responsive.sp(4),
                              vertical: Responsive.sp(4)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQtyButton(
                                icon: Icons.add,
                                onTap: () {
                                  if (!product.isAvailable) return;
                                  final added = cart.addToCart(
                                      product,
                                      shoppingType: _shoppingType);
                                  if (!added && cartQty > 0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'تم الوصول إلى الحد الأقصى للمخزون'),
                                        backgroundColor:
                                            AppColors.warning,
                                        behavior: SnackBarBehavior
                                            .floating,
                                        duration: const Duration(
                                            seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: Responsive.sp(4)),
                                child: Text(
                                  '$cartQty',
                                  style: TextStyle(
                                    color: cartQty > 0
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontSize: Responsive.fp(13),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Space Grotesk',
                                  ),
                                ),
                              ),
                              _buildQtyButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (cartQty <= 0) return;
                                  cart.decreaseQuantity(product.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Product info ──
          Padding(
            padding: EdgeInsets.fromLTRB(Responsive.sp(10),
                Responsive.sp(8), Responsive.sp(10), Responsive.sp(10)),
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
                          arguments: {
                            'product': product,
                            'shoppingType': _shoppingType,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                            vertical: Responsive.sp(8)),
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
    );
  }

  // ── Icon button (heart/comment) ────────────────────────────────

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(Responsive.sp(5)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: Responsive.sp(18)),
              if (count > 0)
                Padding(
                  padding: EdgeInsets.only(top: Responsive.sp(1)),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: Responsive.fp(9),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quantity +/- button ────────────────────────────────────────

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: Responsive.sp(28),
          height: Responsive.sp(28),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Icon(icon, color: Colors.white, size: Responsive.sp(16)),
        ),
      ),
    );
  }
}
