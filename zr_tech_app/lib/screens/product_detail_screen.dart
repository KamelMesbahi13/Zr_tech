import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import '../theme/responsive_wrapper.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

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
        child: Icon(Icons.image_outlined, color: AppColors.textSlate500, size: 56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;
    final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;

    if (product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.textSlate500, size: Responsive.sp(56)),
              SizedBox(height: Responsive.sp(16)),
              Text(
                'المنتج غير موجود',
                style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(16)),
              ),
              SizedBox(height: Responsive.sp(16)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('العودة', style: TextStyle(color: AppColors.primary, fontSize: Responsive.fp(14))),
              ),
            ],
          ),
        ),
      );
    }

    // Image height adapts to screen width
    final imageHeight = Responsive.screenWidth < Breakpoints.mobile
        ? Responsive.sp(220)
        : Responsive.screenWidth < Breakpoints.tablet
            ? Responsive.sp(280)
            : Responsive.sp(340);

    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: Responsive.sp(240),
              height: Responsive.sp(240),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.1),
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
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, Responsive.sp(16), hPad, 0),
                        child: Row(
                          children: [
                            Container(
                              width: Responsive.sp(40),
                              height: Responsive.sp(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceAlt,
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: Responsive.sp(20)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'تفاصيل المنتج',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: Responsive.fp(20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.sp(20)),

                      // Product Image
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Container(
                          height: imageHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.surfaceDark,
                            border: Border.all(color: AppColors.borderDark),
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
                              // Stock badge
                              Positioned(
                                top: Responsive.sp(12),
                                right: Responsive.sp(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: Responsive.sp(14), vertical: Responsive.sp(7)),
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
                                        product.isAvailable
                                            ? Icons.check_circle_outline
                                            : Icons.cancel_outlined,
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
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(24)),

                      // Product Name
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
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

                      // Price Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.sp(20), vertical: Responsive.sp(14)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.cyan.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'DA',
                                style: TextStyle(
                                  color: AppColors.textSlate400,
                                  fontSize: Responsive.fp(16),
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    product.price.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: Responsive.fp(28),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Space Grotesk',
                                    ),
                                  ),
                                  SizedBox(width: Responsive.sp(8)),
                                  Text(
                                    'السعر',
                                    style: TextStyle(
                                      color: AppColors.textSlate400,
                                      fontSize: Responsive.fp(14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(24)),

                      // Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
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
                              padding: EdgeInsets.all(Responsive.sp(16)),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDarkAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderDark),
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

                      // Contact / Order button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: product.isAvailable
                                ? AppColors.primary
                                : AppColors.surfaceAlt,
                            border: product.isAvailable
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: ElevatedButton(
                            onPressed: product.isAvailable
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'سيتم إضافة خاصية الطلب قريباً!',
                                          textAlign: TextAlign.center,
                                        ),
                                        backgroundColor: AppColors.surfaceDarkAlt,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product.isAvailable ? 'اطلب الآن' : 'غير متوفر حالياً',
                                  style: TextStyle(
                                    color: product.isAvailable
                                        ? Colors.white
                                        : AppColors.textSlate500,
                                    fontSize: Responsive.fp(16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: Responsive.sp(8)),
                                Icon(
                                  product.isAvailable
                                      ? Icons.shopping_cart_outlined
                                      : Icons.block,
                                  color: product.isAvailable
                                      ? Colors.white
                                      : AppColors.textSlate500,
                                  size: Responsive.sp(20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(32)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
