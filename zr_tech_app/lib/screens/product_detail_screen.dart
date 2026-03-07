import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_drawer.dart';
import '../theme/responsive_wrapper.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<ProductModel> _products = [];
  int _currentIndex = 0;
  String _shoppingType = 'detail'; // from navigation args
  PageController? _pageController;

  // Per-product image gallery page tracking
  final Map<String, int> _imagePageMap = {};

  // Per-product variant selection tracking
  // Key: product.id, Value: {optionName: selectedValue}
  final Map<String, Map<String, String>> _selectedVariants = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_products.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _shoppingType = args['shoppingType'] as String? ?? 'detail';
        if (args.containsKey('products')) {
          final rawProducts = args['products'];
          if (rawProducts is Iterable) {
            _products = rawProducts.whereType<ProductModel>().toList();
          }
          _currentIndex = args['initialIndex'] as int? ?? 0;
        } else if (args.containsKey('product')) {
          _products = [args['product'] as ProductModel];
          _currentIndex = 0;
        }
      } else if (args is ProductModel) {
        _products = [args];
        _currentIndex = 0;
      }

      if (_products.isNotEmpty) {
        // Start at a high initial page to allow swiping backwards infinitely
        final middleOffset = 1000 * _products.length;
        _pageController = PageController(
          initialPage: middleOffset + _currentIndex,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String imageStr, {BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        );
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(
      imageStr,
      fit: fit,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSlate500,
          size: 56,
        ),
      ),
    );
  }

  // ── Country helpers ──────────────────────────────────────────

  static const Map<String, Map<String, String>> _countryData = {
    'DZ': {'name': 'الجزائر', 'flag': '🇩🇿'},
    'CN': {'name': 'الصين', 'flag': '🇨🇳'},
    'KR': {'name': 'كوريا الجنوبية', 'flag': '🇰🇷'},
    'JP': {'name': 'اليابان', 'flag': '🇯🇵'},
    'TW': {'name': 'تايوان', 'flag': '🇹🇼'},
    'VN': {'name': 'فيتنام', 'flag': '🇻🇳'},
    'IN': {'name': 'الهند', 'flag': '🇮🇳'},
    'TR': {'name': 'تركيا', 'flag': '🇹🇷'},
    'DE': {'name': 'ألمانيا', 'flag': '🇩🇪'},
    'US': {'name': 'الولايات المتحدة', 'flag': '🇺🇸'},
    'MY': {'name': 'ماليزيا', 'flag': '🇲🇾'},
    'TH': {'name': 'تايلاند', 'flag': '🇹🇭'},
    'ID': {'name': 'إندونيسيا', 'flag': '🇮🇩'},
  };

  // ── Color helpers ──────────────────────────────────────────

  static const Map<String, Map<String, dynamic>> _colorData = {
    'black': {'name': 'أسود', 'color': Color(0xFF000000)},
    'white': {'name': 'أبيض', 'color': Color(0xFFFFFFFF)},
    'red': {'name': 'أحمر', 'color': Color(0xFFE53935)},
    'blue': {'name': 'أزرق', 'color': Color(0xFF1E88E5)},
    'green': {'name': 'أخضر', 'color': Color(0xFF43A047)},
    'yellow': {'name': 'أصفر', 'color': Color(0xFFFDD835)},
    'orange': {'name': 'برتقالي', 'color': Color(0xFFFF9800)},
    'pink': {'name': 'وردي', 'color': Color(0xFFE91E63)},
    'purple': {'name': 'بنفسجي', 'color': Color(0xFF9C27B0)},
    'gray': {'name': 'رمادي', 'color': Color(0xFF757575)},
    'gold': {'name': 'ذهبي', 'color': Color(0xFFFFD700)},
    'silver': {'name': 'فضي', 'color': Color(0xFFC0C0C0)},
    'brown': {'name': 'بني', 'color': Color(0xFF795548)},
    'transparent': {'name': 'شفاف', 'color': Color(0x00000000)},
  };

  // ── Warranty helpers ──────────────────────────────────────────

  static const Map<String, String> _warrantyLabels = {
    '1_month': 'شهر واحد',
    '3_months': '3 أشهر',
    '6_months': '6 أشهر',
    '1_year': 'سنة واحدة',
    '2_years': 'سنتين',
  };

  // ── Full-screen image viewer ──────────────────────────────────

  void _showFullScreenImageViewer(List<String> images, int initialIndex) {
    final pageCtrl = PageController(initialPage: initialIndex);
    int currentPage = initialIndex;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              children: [
                PageView.builder(
                  controller: pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setDialogState(() => currentPage = i),
                  itemBuilder: (_, i) {
                    return InteractiveViewer(
                      child: Center(
                        child: _buildImageWidget(images[i], fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
                // Close button
                Positioned(
                  top: 40,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                // Page indicator
                if (images.length > 1)
                  Positioned(
                    bottom: 40,
                    left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentPage + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Specifications card ──────────────────────────────────────────

  Widget _buildSpecificationsCard(ProductModel product) {
    final specs = <Widget>[];

    // Color
    if (product.color != null && _colorData.containsKey(product.color)) {
      final colorInfo = _colorData[product.color]!;
      specs.add(_specChip(
        icon: Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: colorInfo['color'] as Color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark, width: 1),
          ),
        ),
        text: colorInfo['name'] as String,
      ));
    }

    // Condition
    if (product.condition != null) {
      final isOriginal = product.condition == 'original';
      specs.add(_specChip(
        icon: Icon(Icons.verified_outlined, size: 14, color: isOriginal ? AppColors.success : Colors.orange),
        text: isOriginal ? 'أصلي' : 'غير أصلي',
        color: isOriginal ? AppColors.success : Colors.orange,
      ));
    }

    // Box
    if (product.box != null) {
      final hasBox = product.box == 'with_box';
      specs.add(_specChip(
        icon: Icon(Icons.inventory_2_outlined, size: 14, color: hasBox ? AppColors.success : AppColors.textSlate400),
        text: hasBox ? 'مع العلبة' : 'بدون علبة',
        color: hasBox ? AppColors.success : AppColors.textSlate400,
      ));
    }

    // Condition Status
    if (product.conditionStatus != null) {
      final isNew = product.conditionStatus == 'new';
      specs.add(_specChip(
        icon: Icon(Icons.new_releases_outlined, size: 14, color: isNew ? AppColors.success : Colors.orange),
        text: isNew ? 'جديد' : 'مستعمل',
        color: isNew ? AppColors.success : Colors.orange,
      ));
    }

    // Charger
    if (product.charger != null) {
      final hasCharger = product.charger == 'with_charger';
      specs.add(_specChip(
        icon: Icon(Icons.power_outlined, size: 14, color: hasCharger ? AppColors.success : AppColors.textSlate400),
        text: hasCharger ? 'شاحن' : 'بدون شاحن',
        color: hasCharger ? AppColors.success : AppColors.textSlate400,
      ));
    }

    // Headphones
    if (product.headphones != null) {
      final hasHeadphones = product.headphones == 'with_headphones';
      specs.add(_specChip(
        icon: Icon(Icons.headphones_outlined, size: 14, color: hasHeadphones ? AppColors.success : AppColors.textSlate400),
        text: hasHeadphones ? 'سماعات' : 'بدون سماعات',
        color: hasHeadphones ? AppColors.success : AppColors.textSlate400,
      ));
    }

    // Warranty
    if (product.warranty != null && _warrantyLabels.containsKey(product.warranty)) {
      specs.add(_specChip(
        icon: Icon(Icons.security_outlined, size: 14, color: AppColors.primary),
        text: _warrantyLabels[product.warranty]!,
        color: AppColors.primary,
      ));
    }

    // Country of origin
    if (product.countryOfOrigin != null && _countryData.containsKey(product.countryOfOrigin)) {
      final country = _countryData[product.countryOfOrigin]!;
      specs.add(_specChip(
        icon: Text(country['flag']!, style: const TextStyle(fontSize: 13)),
        text: country['name']!,
      ));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specs,
    );
  }

  Widget _specChip({required Widget icon, required String text, Color? color}) {
    final chipColor = color ?? AppColors.textSlate300;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.sp(8), vertical: Responsive.sp(5)),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: Responsive.sp(5)),
          Text(text, style: TextStyle(color: chipColor, fontSize: Responsive.fp(11), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Image gallery with swipe + dot indicators ──────────────────

  Widget _buildImageGallery(ProductModel product, double imageHeight) {
    final images = product.images;
    if (images.isEmpty) {
      return Container(
        height: imageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.borderDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imagePlaceholder(),
      );
    }

    final currentImagePage = _imagePageMap[product.id] ?? 0;

    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image PageView
          if (images.length == 1)
            GestureDetector(
              onTap: () => _showFullScreenImageViewer(images, 0),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _buildImageWidget(images[0]),
              ),
            )
          else
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) {
                if (mounted) setState(() => _imagePageMap[product.id] = i);
              },
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () => _showFullScreenImageViewer(images, i),
                  child: _buildImageWidget(images[i]),
                );
              },
            ),

          // Dot indicators
          if (images.length > 1)
            Positioned(
              bottom: Responsive.sp(10),
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final isActive = i == currentImagePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
            ),

          // Image counter badge
          if (images.length > 1)
            Positioned(
              top: Responsive.sp(12),
              left: Responsive.sp(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.sp(10), vertical: Responsive.sp(5)),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${currentImagePage + 1}/${images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fp(11),
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Availability badge
          Positioned(
            top: Responsive.sp(12),
            right: Responsive.sp(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.sp(14),
                vertical: Responsive.sp(7),
              ),
              decoration: BoxDecoration(
                color: product.isAvailable
                    ? Colors.green.withValues(alpha: 0.9)
                    : Colors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    product.isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: Colors.white,
                    size: Responsive.sp(16),
                  ),
                  SizedBox(width: Responsive.sp(6)),
                  Text(
                    product.isAvailable ? 'متوفر' : 'غير متوفر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fp(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quantity selector overlay
          if (product.isAvailable)
            Positioned(
              right: Responsive.sp(12),
              bottom: Responsive.sp(12),
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final cartItem = cart.getCartItem(product.id);
                  final cartQty = cartItem?.cartQuantity ?? 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.sp(6),
                      vertical: Responsive.sp(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQtyButton(
                          icon: Icons.add,
                          onTap: () {
                            // For variable products, require variant selection first
                            if (product.isVariable) {
                              final selected = _selectedVariants[product.id];
                              final requiredOptions = product.options!.length;
                              if (selected == null || selected.length < requiredOptions) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('الرجاء اختيار جميع الخيارات', textAlign: TextAlign.center),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              final added = cart.addToCart(product, shoppingType: _shoppingType, selectedVariant: selected);
                              if (!added && cartQty > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('الحد الأقصى المتوفر: ${product.getVariantQuantity(selected)}', textAlign: TextAlign.center),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            } else {
                              final added = cart.addToCart(product, shoppingType: _shoppingType);
                              if (!added && cartQty > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('الحد الأقصى المتوفر: ${product.quantity}', textAlign: TextAlign.center),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: Responsive.sp(6)),
                          child: Text(
                            '$cartQty',
                            style: TextStyle(
                              color: cartQty > 0 ? AppColors.primary : AppColors.textMuted,
                              fontSize: Responsive.fp(15),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    if (_products.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.textSlate500,
                  size: Responsive.sp(56),
                ),
                SizedBox(height: Responsive.sp(16)),
                Text(
                  'المنتج غير موجود',
                  style: TextStyle(
                    color: AppColors.textSlate400,
                    fontSize: Responsive.fp(16),
                  ),
                ),
                SizedBox(height: Responsive.sp(16)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'العودة',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: Responsive.fp(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final imageHeight = Responsive.screenWidth < Breakpoints.mobile
        ? Responsive.sp(220)
        : Responsive.screenWidth < Breakpoints.tablet
        ? Responsive.sp(280)
        : Responsive.sp(340);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // ── FIXED HEADER ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      Responsive.sp(16),
                      hPad,
                      Responsive.sp(8),
                    ),
                    child: Row(
                      children: [
                        // Back button
                        Container(
                          width: Responsive.sp(40),
                          height: Responsive.sp(40),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceAlt,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_forward,
                              color: AppColors.textPrimary,
                              size: Responsive.sp(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(width: Responsive.sp(12)),
                        // Title
                        Expanded(
                          child: Text(
                            'تفاصيل المنتج',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: Responsive.fp(20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Cart icon with badge
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
                                              width: 1.5,
                                            ),
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

                  // ── SWIPABLE CONTENT ──
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (!mounted) return;
                        setState(() {
                          _currentIndex = index % _products.length;
                        });
                      },
                      itemBuilder: (context, index) {
                        final product = _products[index % _products.length];
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: Responsive.sp(12)),

                              // ── PRODUCT IMAGE GALLERY ──
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: _buildImageGallery(product, imageHeight),
                              ),
                              SizedBox(height: Responsive.sp(24)),

                              // ── PRODUCT NAME ──
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad + 4,
                                ),
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: Responsive.fp(24),
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(height: Responsive.sp(12)),

                              // ── PRICE CARD ──
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad + 4,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.sp(20),
                                    vertical: Responsive.sp(14),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        AppColors.cyan.withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _shoppingType == 'gros' ? 'سعر الجملة' : 'السعر',
                                            style: TextStyle(
                                              color: AppColors.textSlate400,
                                              fontSize: Responsive.fp(14),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: Responsive.sp(8)),
                                          Text(
                                            product.isVariable
                                                ? (_getSelectedVariantPrice(product)?.toStringAsFixed(0) ?? product.priceRange)
                                                : product.price.toStringAsFixed(0),
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: Responsive.fp(product.isVariable && _getSelectedVariantPrice(product) == null ? 22 : 28),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Space Grotesk',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        'DA',
                                        style: TextStyle(
                                          color: AppColors.textSlate400,
                                          fontSize: Responsive.fp(16),
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ── DETAIL MARKET PRICE (gros only) ──
                              if (_shoppingType == 'gros' && product.detailMarketPrice != null) ...[
                                SizedBox(height: Responsive.sp(10)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.sp(16),
                                      vertical: Responsive.sp(10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.cyan.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.storefront_outlined,
                                          color: AppColors.cyan,
                                          size: Responsive.sp(20),
                                        ),
                                        SizedBox(width: Responsive.sp(8)),
                                        Text(
                                          'سعر التفصيل في السوق',
                                          style: TextStyle(
                                            color: AppColors.textSlate400,
                                            fontSize: Responsive.fp(13),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${product.detailMarketPrice!.toStringAsFixed(0)} DA',
                                          style: TextStyle(
                                            color: AppColors.cyan,
                                            fontSize: Responsive.fp(16),
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Space Grotesk',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // ── MIN QUANTITY (gros only) ──
                              if (_shoppingType == 'gros' &&
                                  product.minQuantity > 1) ...[
                                SizedBox(height: Responsive.sp(10)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: hPad + 4,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.sp(16),
                                      vertical: Responsive.sp(10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.orange,
                                          size: Responsive.sp(20),
                                        ),
                                        SizedBox(width: Responsive.sp(8)),
                                        Text(
                                          'الحد الأدنى للطلب',
                                          style: TextStyle(
                                            color: AppColors.textSlate400,
                                            fontSize: Responsive.fp(14),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Responsive.sp(12),
                                            vertical: Responsive.sp(4),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${product.minQuantity}',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: Responsive.fp(16),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Space Grotesk',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // ── VARIANT SELECTOR (for variable products) ──
                              if (product.isVariable) ...[
                                SizedBox(height: Responsive.sp(16)),
                                ..._buildVariantSelector(product, hPad),
                              ],

                              // ── SPECIFICATIONS CARD ──
                              ..._buildSpecsSection(product, hPad),

                              SizedBox(height: Responsive.sp(24)),

                              // ── DESCRIPTION ──
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad + 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'وصف المنتج',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: Responsive.fp(18),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.sp(12)),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(
                                        Responsive.sp(16),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceDarkAlt,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.borderDark,
                                        ),
                                      ),
                                      child: Text(
                                        product.description.isNotEmpty
                                            ? product.description
                                            : 'لا يوجد وصف لهذا المنتج حالياً.',
                                        style: TextStyle(
                                          color: AppColors.textSlate300,
                                          fontSize: Responsive.fp(15),
                                          height: 1.7,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: Responsive.sp(32)),

                              // ── OUT OF STOCK MESSAGE ──
                              if (!product.isAvailable)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: hPad + 4,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: Responsive.sp(14),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: AppColors.surfaceAlt,
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.block,
                                          color: AppColors.textSlate500,
                                          size: Responsive.sp(20),
                                        ),
                                        SizedBox(width: Responsive.sp(8)),
                                        Text(
                                          'غير متوفر حالياً',
                                          style: TextStyle(
                                            color: AppColors.textSlate500,
                                            fontSize: Responsive.fp(16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              SizedBox(height: Responsive.sp(32)),
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
        ),
      ),
    );
  }

  List<Widget> _buildSpecsSection(ProductModel product, double hPad) {
    final hasSpecs = product.color != null ||
        product.condition != null ||
        product.box != null ||
        product.conditionStatus != null ||
        product.charger != null ||
        product.headphones != null ||
        product.warranty != null ||
        product.countryOfOrigin != null;

    if (!hasSpecs) return [];

    return [
      SizedBox(height: Responsive.sp(16)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
        child: _buildSpecificationsCard(product),
      ),
    ];
  }

  Widget _buildQtyButton({required IconData icon, VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Responsive.sp(36),
        height: Responsive.sp(36),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceAlt
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled
                ? AppColors.borderDark
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isDisabled ? AppColors.textSlate500 : AppColors.primary,
          size: Responsive.sp(18),
        ),
      ),
    );
  }

  // ── Variant selector UI ──────────────────────────────────────────

  /// Get the selected variant price, or null if not all options are selected.
  double? _getSelectedVariantPrice(ProductModel product) {
    if (!product.isVariable) return null;
    final selected = _selectedVariants[product.id];
    if (selected == null || selected.length < product.options!.length) return null;
    return product.getVariantPrice(selected);
  }

  /// Build the variant selector chip groups for a variable product.
  List<Widget> _buildVariantSelector(ProductModel product, double hPad) {
    if (!product.isVariable || product.options == null) return [];

    final selected = _selectedVariants[product.id] ?? {};

    return product.options!.map((option) {
      final optName = option['name'] as String? ?? '';
      final values = (option['values'] as List?)?.cast<String>() ?? [];
      if (optName.isEmpty || values.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              optName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: Responsive.fp(15),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: Responsive.sp(8)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((val) {
                final isSelected = selected[optName] == val;

                // Check stock for this partial combination
                int? variantStock;
                if (product.options!.length == 1 ||
                    (selected.length == product.options!.length - 1 && !selected.containsKey(optName)) ||
                    (selected.length == product.options!.length && selected.containsKey(optName))) {
                  final testCombo = Map<String, String>.from(selected);
                  testCombo[optName] = val;
                  if (testCombo.length == product.options!.length) {
                    variantStock = product.getVariantQuantity(testCombo);
                  }
                }

                final isOutOfStock = variantStock != null && variantStock == 0;

                return GestureDetector(
                  onTap: isOutOfStock ? null : () {
                    setState(() {
                      final current = _selectedVariants[product.id] ?? {};
                      current[optName] = val;
                      _selectedVariants[product.id] = current;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.sp(16),
                      vertical: Responsive.sp(10),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : isOutOfStock
                              ? AppColors.surfaceDarkAlt.withValues(alpha: 0.5)
                              : AppColors.surfaceDarkAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isOutOfStock
                                ? AppColors.borderDark.withValues(alpha: 0.3)
                                : AppColors.borderDark,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          val,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : isOutOfStock
                                    ? AppColors.textSlate500
                                    : AppColors.textPrimary,
                            fontSize: Responsive.fp(13),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (variantStock != null && !isOutOfStock) ...[
                          SizedBox(width: Responsive.sp(6)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.sp(6), vertical: Responsive.sp(2)),
                            decoration: BoxDecoration(
                              color: variantStock > 5
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$variantStock',
                              style: TextStyle(
                                color: variantStock > 5 ? Colors.green : Colors.orange,
                                fontSize: Responsive.fp(10),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Space Grotesk',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: Responsive.sp(12)),
          ],
        ),
      );
    }).toList();
  }
}
