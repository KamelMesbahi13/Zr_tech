import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  // Tracking steps in order
  static const List<String> _trackingSteps = [
    'waiting',
    'preparing',
    'ready',
    'on_the_way',
    'delivered',
    'received',
  ];

  static const Map<String, String> _stepLabels = {
    'waiting': 'في الإنتظار',
    'preparing': 'في التجهيز',
    'ready': 'جاهزة',
    'on_the_way': 'في الطريق',
    'delivered': 'تم التوصيل',
    'received': 'مستلمة',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      final orders = await _orderService
          .getOrdersByUserId(userId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _getStepIndex(String status) {
    // Normalize legacy statuses
    String normalized = status;
    if (status == 'pending') normalized = 'waiting';
    if (status == 'confirmed') normalized = 'preparing';
    final idx = _trackingSteps.indexOf(normalized);
    return idx >= 0 ? idx : 0;
  }

  bool _isCancelledOrRejected(String status) {
    return status == 'cancelled' || status == 'rejected';
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, Responsive.sp(16), hPad, 0),
                  child: Row(
                    children: [
                      Text(
                        'متابعة الطلبات',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: Responsive.fp(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
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
                SizedBox(height: Responsive.sp(16)),
                // Orders list
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      color: AppColors.textSlate500,
                                      size: Responsive.sp(56)),
                                  SizedBox(height: Responsive.sp(16)),
                                  Text(
                                    'لا توجد طلبات حالياً',
                                    style: TextStyle(
                                      color: AppColors.textSlate400,
                                      fontSize: Responsive.fp(16),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(
                                    horizontal: hPad, vertical: Responsive.sp(8)),
                                itemCount: _orders.length,
                                itemBuilder: (ctx, i) =>
                                    _buildOrderCard(_orders[i]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final status = order.normalizedStatus;
    final date = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isNegative = _isCancelledOrRejected(status);

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.sp(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: product info + date + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: Responsive.sp(50),
                    height: Responsive.sp(50),
                    child: _buildProductImage(order.productImage),
                  ),
                ),
                SizedBox(width: Responsive.sp(12)),
                // Product name + quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: Responsive.fp(14),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.sp(4)),
                      Text(
                        'الكمية: ${order.quantity}',
                        style: TextStyle(
                          color: AppColors.textSlate400,
                          fontSize: Responsive.fp(12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.sp(8)),
                // Date + price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: AppColors.textSlate400,
                        fontSize: Responsive.fp(11),
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    SizedBox(height: Responsive.sp(6)),
                    Text(
                      '${order.totalPrice.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: Responsive.fp(16),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: Responsive.sp(16)),

            // Status badge for cancelled/rejected
            if (isNegative) ...[
              _buildNegativeStatusBadge(status),
            ] else ...[
              // Progress bar
              _buildProgressBar(status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNegativeStatusBadge(String status) {
    final isCancelled = status == 'cancelled';
    final color = isCancelled ? AppColors.error : Colors.deepPurple;
    final label = isCancelled ? 'ملغي' : 'مرفوض';
    final icon = isCancelled ? Icons.cancel : Icons.block;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.sp(12),
        vertical: Responsive.sp(8),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Responsive.sp(16)),
          SizedBox(width: Responsive.sp(6)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: Responsive.fp(13),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final currentIdx = _getStepIndex(status);
    final circleSize = Responsive.sp(14);
    final halfCircle = circleSize / 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: halfCircle + 2),
      child: Column(
        children: [
          // Progress line with circles
          SizedBox(
            height: Responsive.sp(32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final stepCount = _trackingSteps.length;
                final segmentWidth = totalWidth / (stepCount - 1);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Background line (gray)
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Progress line (primary) — fills from RIGHT
                    if (currentIdx > 0)
                      Positioned(
                        right: 0,
                        width: segmentWidth * currentIdx,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    // Circles — positioned from RIGHT (step 0 = rightmost)
                    ...List.generate(stepCount, (i) {
                      final isCompleted = i <= currentIdx;
                      final isCurrent = i == currentIdx;
                      final rightPos = i * segmentWidth - halfCircle;

                      return Positioned(
                        right: rightPos,
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.surfaceDark,
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.primary
                                  : AppColors.borderSubtle,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isCompleted
                              ? Icon(
                                  Icons.check,
                                  size: Responsive.sp(8),
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: Responsive.sp(6)),
          // Step labels (Row renders RTL automatically — step 0 on right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_trackingSteps.length, (i) {
              final step = _trackingSteps[i];
              final isCompleted = i <= currentIdx;
              final isCurrent = i == currentIdx;

              return Expanded(
                child: Text(
                  _stepLabels[step] ?? step,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSlate500,
                    fontSize: Responsive.fp(8),
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageStr) {
    if (imageStr.isEmpty) return _imagePlaceholder();
    if (imageStr.startsWith('data:')) {
      try {
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder());
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(imageStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.textSlate500, size: Responsive.sp(24)),
      ),
    );
  }
}
