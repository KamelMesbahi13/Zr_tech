import 'dart:convert';
import 'package:flutter/material.dart';
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

                              // ── PRODUCT IMAGE ──
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: Container(
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppColors.surfaceDark,
                                    border: Border.all(
                                      color: AppColors.borderDark,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: product.image.isNotEmpty
                                            ? _buildImageWidget(product.image)
                                            : _imagePlaceholder(),
                                      ),
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
                                                ? Colors.green.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : Colors.red.withValues(
                                                    alpha: 0.9,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
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
                                                size: Responsive.sp(16),
                                              ),
                                              SizedBox(width: Responsive.sp(6)),
                                              Text(
                                                product.isAvailable
                                                    ? 'متوفر'
                                                    : 'غير متوفر',
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
                                      // Quantity selector overlay on the right (like products grid)
                                      if (product.isAvailable)
                                        Positioned(
                                          right: Responsive.sp(12),
                                          bottom: Responsive.sp(12),
                                          child: Consumer<CartProvider>(
                                            builder: (context, cart, _) {
                                              final cartItem = cart.getCartItem(
                                                product.id,
                                              );
                                              final cartQty =
                                                  cartItem?.cartQuantity ?? 0;
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.92),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: Responsive.sp(6),
                                                  vertical: Responsive.sp(6),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _buildQtyButton(
                                                      icon: Icons.add,
                                                      onTap: () {
                                                        final added = cart
                                                            .addToCart(
                                                              product,
                                                              shoppingType:
                                                                  _shoppingType,
                                                            );
                                                        if (!added &&
                                                            cartQty > 0) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'الحد الأقصى المتوفر: ${product.quantity}',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                              backgroundColor:
                                                                  AppColors
                                                                      .warning,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 1,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                Responsive.sp(
                                                                  6,
                                                                ),
                                                          ),
                                                      child: Text(
                                                        '$cartQty',
                                                        style: TextStyle(
                                                          color: cartQty > 0
                                                              ? AppColors
                                                                    .primary
                                                              : AppColors
                                                                    .textMuted,
                                                          fontSize:
                                                              Responsive.fp(15),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'Space Grotesk',
                                                        ),
                                                      ),
                                                    ),
                                                    _buildQtyButton(
                                                      icon: Icons.remove,
                                                      onTap: () {
                                                        if (cartQty <= 0)
                                                          return;
                                                        cart.decreaseQuantity(
                                                          product.id,
                                                        );
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
                                            'السعر',
                                            style: TextStyle(
                                              color: AppColors.textSlate400,
                                              fontSize: Responsive.fp(14),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: Responsive.sp(8)),
                                          Text(
                                            product.price.toStringAsFixed(0),
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: Responsive.fp(28),
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

                              // ── QUANTITY SELECTOR WAS MOVED TO IMAGE OVERLAY ──
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
}
