import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_drawer.dart';
import '../theme/responsive_wrapper.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/wilaya_service.dart';

/// All 69 Algerian wilayas with default delivery prices.
class _WilayaData {
  final String id;
  final String name;
  double homePrice;
  double deskPrice;
  _WilayaData(this.id, this.name, {this.homePrice = 600, this.deskPrice = 400});

  String get displayName => '$id - $name';
}

final List<_WilayaData> _algerianWilayas = [
  _WilayaData('01', 'أدرار'),
  _WilayaData('02', 'الشلف'),
  _WilayaData('03', 'الأغواط'),
  _WilayaData('04', 'أم البواقي'),
  _WilayaData('05', 'باتنة'),
  _WilayaData('06', 'بجاية'),
  _WilayaData('07', 'بسكرة'),
  _WilayaData('08', 'بشار'),
  _WilayaData('09', 'البليدة'),
  _WilayaData('10', 'البويرة'),
  _WilayaData('11', 'تمنراست'),
  _WilayaData('12', 'تبسة'),
  _WilayaData('13', 'تلمسان'),
  _WilayaData('14', 'تيارت'),
  _WilayaData('15', 'تيزي وزو'),
  _WilayaData('16', 'الجزائر'),
  _WilayaData('17', 'الجلفة'),
  _WilayaData('18', 'جيجل'),
  _WilayaData('19', 'سطيف'),
  _WilayaData('20', 'سعيدة'),
  _WilayaData('21', 'سكيكدة'),
  _WilayaData('22', 'سيدي بلعباس'),
  _WilayaData('23', 'عنابة'),
  _WilayaData('24', 'قالمة'),
  _WilayaData('25', 'قسنطينة'),
  _WilayaData('26', 'المدية'),
  _WilayaData('27', 'مستغانم'),
  _WilayaData('28', 'المسيلة'),
  _WilayaData('29', 'معسكر'),
  _WilayaData('30', 'ورقلة'),
  _WilayaData('31', 'وهران'),
  _WilayaData('32', 'البيض'),
  _WilayaData('33', 'إليزي'),
  _WilayaData('34', 'برج بوعريريج'),
  _WilayaData('35', 'بومرداس'),
  _WilayaData('36', 'الطارف'),
  _WilayaData('37', 'تندوف'),
  _WilayaData('38', 'تيسمسيلت'),
  _WilayaData('39', 'الوادي'),
  _WilayaData('40', 'خنشلة'),
  _WilayaData('41', 'سوق أهراس'),
  _WilayaData('42', 'تيبازة'),
  _WilayaData('43', 'ميلة'),
  _WilayaData('44', 'عين الدفلى'),
  _WilayaData('45', 'النعامة'),
  _WilayaData('46', 'عين تموشنت'),
  _WilayaData('47', 'غرداية'),
  _WilayaData('48', 'غليزان'),
  _WilayaData('49', 'تيميمون'),
  _WilayaData('50', 'برج باجي مختار'),
  _WilayaData('51', 'أولاد جلال'),
  _WilayaData('52', 'بني عباس'),
  _WilayaData('53', 'عين صالح'),
  _WilayaData('54', 'عين قزام'),
  _WilayaData('55', 'توقرت'),
  _WilayaData('56', 'جانت'),
  _WilayaData('57', 'المغير'),
  _WilayaData('58', 'المنيعة'),
  _WilayaData('59', 'بريان'),
  _WilayaData('60', 'أفلو'),
  _WilayaData('61', 'عين وسارة'),
  _WilayaData('62', 'المقارين'),
  _WilayaData('63', 'بوسعادة'),
  _WilayaData('64', 'المرسى'),
  _WilayaData('65', 'حاسي مسعود'),
  _WilayaData('66', 'تقرت'),
  _WilayaData('67', 'الأوراس'),
  _WilayaData('68', 'عين الإبل'),
  _WilayaData('69', 'سيدي المهدي'),
];

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Order form state
  bool _showOrderForm = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final OrderService _orderService = OrderService();
  final WilayaService _wilayaService = WilayaService();
  final AuthService _authService = AuthService();

  _WilayaData? _selectedWilaya;
  List<_WilayaData> _displayWilayas = List.from(_algerianWilayas);
  int _quantity = 1;
  String _shippingType = 'home';
  bool _isSubmitting = false;
  bool _isLoadingPrices = false;
  bool _isLoggedIn = false;
  String _userWilayaName = '';
  String _shoppingType = 'detail'; // from navigation args

  ProductModel? _product;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Fetch wilayas from Firebase. Firebase is the primary source;
  /// the hardcoded list is only a fallback if Firebase fails.
  Future<void> _loadWilayasFromFirebase() async {
    setState(() => _isLoadingPrices = true);
    try {
      final fbWilayas = await _wilayaService.getActiveWilayas();
      if (!mounted) return;
      if (fbWilayas.isNotEmpty) {
        // Build display list from Firebase data (admin-managed)
        _displayWilayas = fbWilayas.map((w) => _WilayaData(
          w.id,
          w.name,
          homePrice: w.homeDeliveryPrice,
          deskPrice: w.deskDeliveryPrice,
        )).toList();
      }
      // else keep the hardcoded fallback
    } catch (_) {
      // Firebase failed — keep hardcoded fallback
    }
    if (!mounted) return;
    setState(() => _isLoadingPrices = false);
  }

  /// Load logged-in user data (for gros users) and auto-fill form fields
  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final userData = await _authService.getCurrentUserData();
      if (!mounted || userData == null) return;

      final nameParts = userData.name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      setState(() {
        _isLoggedIn = true;
        _firstNameController.text = firstName;
        _lastNameController.text = lastName;
        _phoneController.text = userData.phone;
        _addressController.text = userData.storeName;
        _userWilayaName = userData.wilaya;
        _tryPreSelectWilaya();
      });
    } catch (_) {}
  }

  void _tryPreSelectWilaya() {
    if (_userWilayaName.isEmpty || _displayWilayas.isEmpty) return;
    try {
      final match = _displayWilayas.firstWhere(
        (w) => w.name == _userWilayaName,
      );
      _selectedWilaya = match;
    } catch (_) {}
  }

  double get _deliveryPrice {
    if (_selectedWilaya == null) return 0;
    return _shippingType == 'home'
        ? _selectedWilaya!.homePrice
        : _selectedWilaya!.deskPrice;
  }

  double get _subtotal => (_product?.price ?? 0) * _quantity;
  double get _total => _subtotal + _deliveryPrice;

  String _resolveShoppingType() {
    return _shoppingType;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null) {
      _showSnackBar('الرجاء اختيار الولاية', isError: true);
      return;
    }
    if (_product == null) return;

    setState(() => _isSubmitting = true);

    try {
      final order = OrderModel(
        orderId: '',
        productId: _product!.id,
        productName: _product!.name,
        productImage: _product!.image,
        productPrice: _product!.price,
        categoryId: _product!.categoryId,
        shoppingType: _resolveShoppingType(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        wilaya: _selectedWilaya!.name,
        address: _addressController.text.trim(),
        quantity: _quantity,
        shippingType: _shippingType,
        deliveryPrice: _deliveryPrice,
        totalPrice: _total,
      );

      await _orderService.placeOrder(order);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('حدث خطأ أثناء تأكيد الطلب', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: Responsive.sp(8)),
              Container(
                width: Responsive.sp(72),
                height: Responsive.sp(72),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.check_circle, color: AppColors.success, size: Responsive.sp(44)),
              ),
              SizedBox(height: Responsive.sp(20)),
              Text(
                'تم تأكيد طلبك بنجاح!',
                style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(20), fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.sp(8)),
              Text(
                'سيتم التواصل معك قريباً لتأكيد التوصيل',
                style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.sp(24)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _showOrderForm = false;
                      _resetForm();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: Responsive.sp(14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('حسناً', style: TextStyle(color: Colors.white, fontSize: Responsive.fp(16), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedWilaya = null;
    _quantity = 1;
    _shippingType = 'home';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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

    if (_product == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _product = args['product'] as ProductModel?;
        _shoppingType = args['shoppingType'] as String? ?? 'detail';
      } else if (args is ProductModel) {
        _product = args;
      }
    }

    if (_product == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.textSlate500, size: Responsive.sp(56)),
                SizedBox(height: Responsive.sp(16)),
                Text('المنتج غير موجود', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(16))),
                SizedBox(height: Responsive.sp(16)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('العودة', style: TextStyle(color: AppColors.primary, fontSize: Responsive.fp(14))),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final imageHeight = Responsive.screenWidth < Breakpoints.mobile
        ? Responsive.sp(220)
        : Responsive.screenWidth < Breakpoints.tablet
            ? Responsive.sp(280)
            : Responsive.sp(340);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
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
                              Text(
                                'تفاصيل المنتج',
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
                                  onPressed: () {
                                    if (_showOrderForm) {
                                      setState(() => _showOrderForm = false);
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                  icon: Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: Responsive.sp(20)),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.sp(20)),

                        // ── PRODUCT IMAGE ──
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
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
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
                                          style: TextStyle(color: Colors.white, fontSize: Responsive.fp(13), fontWeight: FontWeight.bold),
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

                        // ── PRODUCT NAME ──
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                          child: Text(
                            product.name,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(24), fontWeight: FontWeight.bold, height: 1.3),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: Responsive.sp(12)),

                        // ── PRICE CARD ──
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.sp(20), vertical: Responsive.sp(14)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.cyan.withValues(alpha: 0.08)],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Text('السعر', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14), fontWeight: FontWeight.w500)),
                                    SizedBox(width: Responsive.sp(8)),
                                    Text(product.price.toStringAsFixed(0), style: TextStyle(color: AppColors.primaryLight, fontSize: Responsive.fp(28), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                                  ],
                                ),
                                const Spacer(),
                                Text('DA', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(16), fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),

                        // ── QUANTITY LEFT (gros only) ──
                        if (_shoppingType == 'gros') ...[
                          SizedBox(height: Responsive.sp(10)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.sp(16), vertical: Responsive.sp(10)),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDarkAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: product.quantity > 10
                                        ? AppColors.success
                                        : product.quantity > 5
                                            ? AppColors.warning
                                            : Colors.red,
                                    size: Responsive.sp(20),
                                  ),
                                  SizedBox(width: Responsive.sp(8)),
                                  Text(
                                    'الكمية المتبقية',
                                    style: TextStyle(
                                      color: AppColors.textSlate400,
                                      fontSize: Responsive.fp(14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: Responsive.sp(12), vertical: Responsive.sp(4)),
                                    decoration: BoxDecoration(
                                      color: (product.quantity > 10
                                              ? AppColors.success
                                              : product.quantity > 5
                                                  ? AppColors.warning
                                                  : Colors.red)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${product.quantity}',
                                      style: TextStyle(
                                        color: product.quantity > 10
                                            ? AppColors.success
                                            : product.quantity > 5
                                                ? AppColors.warning
                                                : Colors.red,
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
                          padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('وصف المنتج', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(18), fontWeight: FontWeight.bold)),
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
                                  product.description.isNotEmpty ? product.description : 'لا يوجد وصف لهذا المنتج حالياً.',
                                  style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(15), height: 1.7),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.sp(32)),

                        // ── BUTTONS (hidden when form is shown) ──
                        if (!_showOrderForm) ...[
                          // Add to Cart button
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: product.isAvailable ? AppColors.primary : AppColors.surfaceAlt,
                                border: product.isAvailable ? null : Border.all(color: AppColors.border),
                              ),
                              child: ElevatedButton(
                                onPressed: product.isAvailable
                                    ? () {
                                        final cart = Provider.of<CartProvider>(context, listen: false);
                                        final added = cart.addToCart(product, shoppingType: _shoppingType);
                                        if (!added) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('الحد الأقصى المتوفر: ${product.quantity}', textAlign: TextAlign.center),
                                              backgroundColor: AppColors.warning,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        showCartDrawer(context);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      product.isAvailable ? Icons.add_shopping_cart : Icons.block,
                                      color: product.isAvailable ? Colors.white : AppColors.textSlate500,
                                      size: Responsive.sp(20),
                                    ),
                                    SizedBox(width: Responsive.sp(8)),
                                    Text(
                                      product.isAvailable ? 'أضف إلى السلة' : 'غير متوفر حالياً',
                                      style: TextStyle(
                                        color: product.isAvailable ? Colors.white : AppColors.textSlate500,
                                        fontSize: Responsive.fp(16),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: Responsive.sp(12)),

                          // Buy Now button
                          if (product.isAvailable)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [AppColors.success, AppColors.success.withValues(alpha: 0.85)],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showOrderForm = true);
                                    _loadWilayasFromFirebase();
                                    _loadUserData();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.flash_on, color: Colors.white, size: Responsive.sp(20)),
                                      SizedBox(width: Responsive.sp(8)),
                                      Text('اشتري الآن', style: TextStyle(color: Colors.white, fontSize: Responsive.fp(16), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],

                        // ── ORDER FORM (shown below description when Buy Now is clicked) ──
                        if (_showOrderForm)
                          _buildInlineOrderForm(product, hPad),

                        SizedBox(height: Responsive.sp(32)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── INLINE ORDER FORM ─────────────────────────────────────────

  Widget _buildInlineOrderForm(ProductModel product, double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad + 4),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title
            _buildSectionTitle('معلومات الزبون', Icons.person_outline),
            SizedBox(height: Responsive.sp(12)),

            // Name row
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _firstNameController,
                    label: 'الاسم',
                    hint: 'الاسم',
                    icon: Icons.person_outline,
                    readOnly: _isLoggedIn,
                    validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                ),
                SizedBox(width: Responsive.sp(12)),
                Expanded(
                  child: _buildFormField(
                    controller: _lastNameController,
                    label: 'اللقب',
                    hint: 'اللقب',
                    icon: Icons.badge_outlined,
                    readOnly: _isLoggedIn,
                    validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.sp(12)),

            // Phone
            _buildFormField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              hint: '0XX XXX XXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isPhoneField: true,
              readOnly: _isLoggedIn,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                if (v.trim().length < 9) return 'رقم الهاتف غير صحيح';
                return null;
              },
            ),
            SizedBox(height: Responsive.sp(20)),

            // Delivery section
            _buildSectionTitle('معلومات التوصيل', Icons.local_shipping_outlined),
            SizedBox(height: Responsive.sp(12)),

            // Wilaya dropdown
            _buildWilayaDropdown(),
            SizedBox(height: Responsive.sp(12)),

            // Address
            _buildFormField(
              controller: _addressController,
              label: 'العنوان بالتفصيل',
              hint: 'الحي، الشارع، رقم المنزل...',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              readOnly: _isLoggedIn,
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            SizedBox(height: Responsive.sp(12)),

            // Shipping type
            _buildShippingTypeToggle(),
            SizedBox(height: Responsive.sp(20)),

            // Quantity
            _buildSectionTitle('الكمية', Icons.shopping_bag_outlined),
            SizedBox(height: Responsive.sp(12)),
            _buildQuantitySelector(product),
            SizedBox(height: Responsive.sp(24)),

            // Order summary
            _buildOrderSummary(product),
            SizedBox(height: Responsive.sp(24)),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.sp(6)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: Responsive.sp(18)),
        ),
        SizedBox(width: Responsive.sp(8)),
        Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(17), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPhoneField = false,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(13), fontWeight: FontWeight.w500)),
        SizedBox(height: Responsive.sp(6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: isPhoneField ? TextDirection.ltr : TextDirection.rtl,
          textAlign: isPhoneField ? TextAlign.left : TextAlign.right,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? AppColors.textSlate400 : AppColors.textPrimary, fontSize: Responsive.fp(14), fontFamily: isPhoneField ? 'Space Grotesk' : null),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(13), fontFamily: isPhoneField ? 'Space Grotesk' : null),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(icon, color: AppColors.textSlate400, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: EdgeInsets.symmetric(horizontal: Responsive.sp(16), vertical: Responsive.sp(14)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
          ),
        ),
      ],
    );
  }

  Widget _buildWilayaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الولاية', style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(13), fontWeight: FontWeight.w500)),
        SizedBox(height: Responsive.sp(6)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<_WilayaData>(
            initialValue: _selectedWilaya,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSlate400),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.location_city_outlined, color: AppColors.textSlate400, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              contentPadding: EdgeInsets.symmetric(horizontal: Responsive.sp(16), vertical: Responsive.sp(4)),
              border: InputBorder.none,
            ),
            hint: Text('اختر الولاية', style: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(13))),
            style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(14)),
            dropdownColor: AppColors.surface,
            menuMaxHeight: 300,
            items: _displayWilayas.map((w) {
              return DropdownMenuItem<_WilayaData>(
                value: w,
                child: Text(
                  w.displayName,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(14)),
                  textDirection: TextDirection.rtl,
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedWilaya = val),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع التوصيل', style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(13), fontWeight: FontWeight.w500)),
        SizedBox(height: Responsive.sp(6)),
        Container(
          padding: EdgeInsets.all(Responsive.sp(4)),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _shippingType = 'home'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: Responsive.sp(12)),
                    decoration: BoxDecoration(
                      color: _shippingType == 'home' ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, size: Responsive.sp(18), color: _shippingType == 'home' ? Colors.white : AppColors.textSlate400),
                        SizedBox(width: Responsive.sp(6)),
                        Text(
                          'إلى المنزل',
                          style: TextStyle(
                            color: _shippingType == 'home' ? Colors.white : AppColors.textSlate400,
                            fontSize: Responsive.fp(13),
                            fontWeight: _shippingType == 'home' ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _shippingType = 'desk'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: Responsive.sp(12)),
                    decoration: BoxDecoration(
                      color: _shippingType == 'desk' ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: Responsive.sp(18), color: _shippingType == 'desk' ? Colors.white : AppColors.textSlate400),
                        SizedBox(width: Responsive.sp(6)),
                        Text(
                          'إلى المكتب',
                          style: TextStyle(
                            color: _shippingType == 'desk' ? Colors.white : AppColors.textSlate400,
                            fontSize: Responsive.fp(13),
                            fontWeight: _shippingType == 'desk' ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ProductModel product) {
    final maxQty = product.quantity;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.sp(16), vertical: Responsive.sp(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Qty controls
          _buildQtyButton(icon: Icons.add, onTap: _quantity < maxQty ? () => setState(() => _quantity++) : null),
          Container(
            width: Responsive.sp(56),
            alignment: Alignment.center,
            child: Text('$_quantity', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(20), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          ),
          _buildQtyButton(icon: Icons.remove, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
          const Spacer(),
          // Stock info
          Text('المتوفر: $maxQty', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(13))),
        ],
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
          color: isDisabled ? AppColors.surfaceAlt : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDisabled ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: isDisabled ? AppColors.textSlate500 : AppColors.primary, size: Responsive.sp(18)),
      ),
    );
  }

  Widget _buildOrderSummary(ProductModel product) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.cyan.withValues(alpha: 0.04)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: Responsive.sp(20)),
              SizedBox(width: Responsive.sp(8)),
              Text('ملخص الطلب', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(17), fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: Responsive.sp(16)),
          Divider(color: AppColors.primary.withValues(alpha: 0.1), height: 1),
          SizedBox(height: Responsive.sp(14)),

          _buildSummaryRow('سعر المنتج', '${product.price.toStringAsFixed(0)} × $_quantity', '${_subtotal.toStringAsFixed(0)} DA'),
          SizedBox(height: Responsive.sp(10)),

          _buildSummaryRow(
            'سعر التوصيل${_shippingType == 'home' ? ' (منزل)' : ' (مكتب)'}',
            _selectedWilaya != null ? _selectedWilaya!.name : 'اختر الولاية',
            _selectedWilaya != null ? '${_deliveryPrice.toStringAsFixed(0)} DA' : '---',
          ),
          SizedBox(height: Responsive.sp(14)),
          Divider(color: AppColors.primary.withValues(alpha: 0.1), height: 1),
          SizedBox(height: Responsive.sp(14)),

          Row(
            children: [
              Text('الإجمالي', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(16), fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_total.toStringAsFixed(0)} DA', style: TextStyle(color: AppColors.primaryDark, fontSize: Responsive.fp(22), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String detail, String value) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(13))),
            Text(detail, style: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(11), fontFamily: 'Space Grotesk')),
          ],
        ),
        const Spacer(),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(14), fontWeight: FontWeight.w600, fontFamily: 'Space Grotesk')),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: Responsive.sp(20)),
                  SizedBox(width: Responsive.sp(8)),
                  Text('تأكيد الطلب', style: TextStyle(color: Colors.white, fontSize: Responsive.fp(16), fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
