import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';

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
    final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;

    if (product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.textSlate500, size: 56),
              const SizedBox(height: 16),
              const Text(
                'المنتج غير موجود',
                style: TextStyle(color: AppColors.textSlate400, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
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
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        const Text(
                          'تفاصيل المنتج',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 280,
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
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    product.isAvailable ? 'متوفر' : 'غير متوفر',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
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
                  const SizedBox(height: 24),

                  // Product Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          const Text(
                            'DA',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 16,
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                product.price.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Space Grotesk',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'السعر',
                                style: TextStyle(
                                  color: AppColors.textSlate400,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'وصف المنتج',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDarkAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Text(
                            product.description.isNotEmpty
                                ? product.description
                                : 'لا يوجد وصف لهذا المنتج حالياً.',
                            style: const TextStyle(
                              color: AppColors.textSlate300,
                              fontSize: 15,
                              height: 1.7,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact / Order button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: product.isAvailable
                            ? AppColors.primaryGradient
                            : null,
                        color: product.isAvailable
                            ? null
                            : AppColors.surfaceDarkAlt,
                        boxShadow: product.isAvailable
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                        border: product.isAvailable
                            ? null
                            : Border.all(color: AppColors.borderDark),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              product.isAvailable
                                  ? Icons.shopping_cart_outlined
                                  : Icons.block,
                              color: product.isAvailable
                                  ? Colors.white
                                  : AppColors.textSlate500,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
