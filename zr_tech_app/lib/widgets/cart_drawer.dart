import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';

/// Shows the cart as a slide-in panel from the RIGHT side of the screen,
/// with a dark overlay behind it.
void showCartDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cart',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _CartPanel();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from right edge regardless of text direction
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0), // off-screen right
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(
        position: offsetAnimation,
        textDirection: TextDirection.ltr, // force LTR so 1.0 = right
        child: child,
      );
    },
  );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  Widget _buildProductImage(String imageStr) {
    if (imageStr.isEmpty) return _imagePlaceholder();

    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder());
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(imageStr, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  static Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textSlate500, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Panel width: 85% of screen, max 400px
    final panelWidth = (screenWidth * 0.85).clamp(0.0, 400.0);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Column(
                    children: [
                      // ─── Header ───────────────────────────────
                      _buildHeader(context, cart),

                      // ─── Divider ──────────────────────────────
                      Container(
                        height: 1,
                        color: AppColors.border,
                      ),

                      // ─── Cart Items or Empty State ────────────
                      Expanded(
                        child: cart.items.isEmpty
                            ? _buildEmptyState()
                            : _buildItemList(context, cart),
                      ),

                      // ─── Footer (Total + Checkout) ────────────
                      if (cart.items.isNotEmpty) _buildFooter(context, cart),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cart) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.sp(20), Responsive.sp(20), Responsive.sp(20), Responsive.sp(16)),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: Responsive.sp(36),
              height: Responsive.sp(36),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceAlt,
              ),
              child: Icon(Icons.close, size: Responsive.sp(18), color: AppColors.textPrimary),
            ),
          ),
          const Spacer(),
          // Title + badge
          Row(
            children: [
              if (cart.totalItems > 0)
                Container(
                  margin: EdgeInsets.only(left: Responsive.sp(8)),
                  padding: EdgeInsets.symmetric(
                      horizontal: Responsive.sp(10), vertical: Responsive.sp(4)),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.totalItems}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fp(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(width: Responsive.sp(8)),
              Text(
                'السلة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: Responsive.sp(8)),
              Icon(Icons.shopping_cart_outlined,
                  color: AppColors.primary, size: Responsive.sp(22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Responsive.sp(80),
            height: Responsive.sp(80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.shopping_cart_outlined,
                color: AppColors.primary.withValues(alpha: 0.5),
                size: Responsive.sp(40)),
          ),
          SizedBox(height: Responsive.sp(20)),
          Text(
            'السلة فارغة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: Responsive.fp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.sp(8)),
          Text(
            'أضف منتجات للبدء بالتسوق',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: Responsive.fp(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, CartProvider cart) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.sp(16), vertical: Responsive.sp(12)),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => SizedBox(height: Responsive.sp(12)),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Container(
          padding: EdgeInsets.all(Responsive.sp(12)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: Responsive.sp(72),
                  height: Responsive.sp(72),
                  child: _buildProductImage(item.product.image),
                ),
              ),
              SizedBox(width: Responsive.sp(12)),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + delete
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: Responsive.fp(14),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => cart.removeFromCart(item.product.id),
                          child: Container(
                            padding: EdgeInsets.all(Responsive.sp(4)),
                            child: Icon(Icons.delete_outline,
                                color: AppColors.error,
                                size: Responsive.sp(18)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.sp(8)),

                    // Price + Quantity controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Unit price
                        Text(
                          '${item.product.price.toStringAsFixed(0)} DA',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: Responsive.fp(14),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),

                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decrease
                              _quantityButton(
                                icon: Icons.remove,
                                onTap: () => cart.decreaseQuantity(item.product.id),
                              ),
                              // Current qty
                              Container(
                                constraints: BoxConstraints(
                                    minWidth: Responsive.sp(32)),
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.cartQuantity}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: Responsive.fp(14),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Space Grotesk',
                                  ),
                                ),
                              ),
                              // Increase
                              _quantityButton(
                                icon: Icons.add,
                                onTap: () {
                                  final ok = cart.increaseQuantity(item.product.id);
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'الحد الأقصى المتوفر: ${item.product.quantity}',
                                          textAlign: TextAlign.center,
                                        ),
                                        backgroundColor: AppColors.warning,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quantityButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Responsive.sp(32),
        height: Responsive.sp(32),
        alignment: Alignment.center,
        child: Icon(icon, size: Responsive.sp(16), color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(20)),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.fp(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${cart.totalPrice.toStringAsFixed(0)} DA',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: Responsive.fp(22),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.sp(16)),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close cart drawer
                Navigator.of(context).pushNamed('/cart-checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: Responsive.sp(14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الدفع',
                    style: TextStyle(
                      fontSize: Responsive.fp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: Responsive.sp(8)),
                  Icon(Icons.arrow_back, size: Responsive.sp(18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
