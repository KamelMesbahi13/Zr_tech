import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../models/order_model.dart';
import '../models/wilaya_model.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/wilaya_service.dart';

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final WilayaService _wilayaService = WilayaService();
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();

  List<WilayaModel> _wilayas = [];
  WilayaModel? _selectedWilaya;
  String _shippingType = 'home';
  bool _isLoadingWilayas = true;
  bool _isSubmitting = false;
  bool _isLoggedIn = false; // true for gros users (auto-fill & read-only)
  String _userWilayaName = '';

  @override
  void initState() {
    super.initState();
    _loadWilayas();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadWilayas() async {
    try {
      await _wilayaService.seedWilayas();
      final wilayas = await _wilayaService.getActiveWilayas();
      if (!mounted) return;
      setState(() {
        _wilayas = wilayas;
        _isLoadingWilayas = false;
        // If user data loaded already, try to pre-select wilaya
        _tryPreSelectWilaya();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingWilayas = false);
    }
  }

  /// Load logged-in user data (for gros users) and auto-fill fields
  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return; // detail user, not logged in

      final userData = await _authService.getCurrentUserData();
      if (!mounted || userData == null) return;

      // Split name into first/last (use full name as first if single word)
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
    } catch (_) {
      // Silently fail — user can fill manually
    }
  }

  /// Try to match user's wilaya name with the loaded wilayas list
  void _tryPreSelectWilaya() {
    if (_userWilayaName.isEmpty || _wilayas.isEmpty) return;
    try {
      final match = _wilayas.firstWhere(
        (w) => w.name == _userWilayaName,
      );
      _selectedWilaya = match;
    } catch (_) {
      // No match found
    }
  }

  double get _deliveryPrice {
    if (_selectedWilaya == null) return 0;
    return _shippingType == 'home'
        ? _selectedWilaya!.homeDeliveryPrice
        : _selectedWilaya!.deskDeliveryPrice;
  }

  double _cartSubtotal(CartProvider cart) =>
      cart.items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double _cartTotal(CartProvider cart) => _cartSubtotal(cart) + _deliveryPrice;

  Future<void> _submitOrders() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null) {
      _showSnackBar('الرجاء اختيار الولاية', isError: true);
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      // Place one order per cart item, sharing customer & delivery info
      for (final item in cart.items) {
        final itemSubtotal = item.lineTotal;
        final itemTotal = itemSubtotal + _deliveryPrice;

        final order = OrderModel(
          orderId: '',
          productId: item.product.id,
          productName: item.product.name,
          productImage: item.product.image,
          productPrice: item.product.price,
          categoryId: item.product.categoryId,
          shoppingType: '', // cart items don't track shopping type
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          wilaya: _selectedWilaya!.name,
          address: _addressController.text.trim(),
          quantity: item.cartQuantity,
          shippingType: _shippingType,
          deliveryPrice: _deliveryPrice,
          totalPrice: itemTotal,
        );

        await _orderService.placeOrder(order);
      }

      // Clear the cart after all orders are placed
      cart.clearCart();

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                child: Icon(Icons.check_circle,
                    color: AppColors.success, size: Responsive.sp(44)),
              ),
              SizedBox(height: Responsive.sp(20)),
              Text(
                'تم تأكيد طلباتك بنجاح!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(20),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.sp(8)),
              Text(
                'سيتم التواصل معك قريباً لتأكيد التوصيل',
                style: TextStyle(
                  color: AppColors.textSlate400,
                  fontSize: Responsive.fp(14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.sp(24)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        EdgeInsets.symmetric(vertical: Responsive.sp(14)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'العودة للتسوق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // ─── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            hPad, Responsive.sp(16), hPad, 0),
                        child: Row(
                          children: [
                            Text(
                              'إتمام الشراء',
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
                      SizedBox(height: Responsive.sp(12)),

                      // Form content
                      Expanded(
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            if (cart.items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined,
                                        color: AppColors.textSlate500,
                                        size: Responsive.sp(56)),
                                    SizedBox(height: Responsive.sp(16)),
                                    Text('السلة فارغة',
                                        style: TextStyle(
                                            color: AppColors.textSlate400,
                                            fontSize: Responsive.fp(16))),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              padding:
                                  EdgeInsets.symmetric(horizontal: hPad),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Cart items summary
                                    _buildCartItemsSummary(cart),
                                    SizedBox(height: Responsive.sp(20)),

                                    // Customer info
                                    _buildSectionTitle(
                                        'معلومات الزبون', Icons.person_outline),
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
                                            validator: (v) =>
                                                v == null ||
                                                        v.trim().isEmpty
                                                    ? 'مطلوب'
                                                    : null,
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
                                            validator: (v) =>
                                                v == null ||
                                                        v.trim().isEmpty
                                                    ? 'مطلوب'
                                                    : null,
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
                                      isLTR: true,
                                      readOnly: _isLoggedIn,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'مطلوب';
                                        if (v.trim().length < 9)
                                          return 'رقم الهاتف غير صحيح';
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: Responsive.sp(20)),

                                    // Delivery section
                                    _buildSectionTitle(
                                        'معلومات التوصيل',
                                        Icons.local_shipping_outlined),
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
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'مطلوب'
                                              : null,
                                    ),
                                    SizedBox(height: Responsive.sp(12)),

                                    // Shipping type toggle
                                    _buildShippingTypeToggle(),
                                    SizedBox(height: Responsive.sp(24)),

                                    // Order summary
                                    _buildOrderSummary(cart),
                                    SizedBox(height: Responsive.sp(24)),

                                    // Submit button
                                    _buildSubmitButton(),
                                    SizedBox(height: Responsive.sp(32)),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }

  // ─── CART ITEMS SUMMARY ──────────────────────────────────────

  Widget _buildCartItemsSummary(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.sp(6)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_cart_outlined,
                    color: AppColors.primary, size: Responsive.sp(18)),
              ),
              SizedBox(width: Responsive.sp(8)),
              Text(
                'المنتجات (${cart.totalItems})',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.sp(14)),
          ...cart.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.sp(10)),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: Responsive.sp(50),
                        height: Responsive.sp(50),
                        child: _buildProductImage(item.product.image),
                      ),
                    ),
                    SizedBox(width: Responsive.sp(10)),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: Responsive.fp(13),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Responsive.sp(2)),
                          Text(
                            '${item.product.price.toStringAsFixed(0)} DA × ${item.cartQuantity}',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: Responsive.fp(12),
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Line total
                    Text(
                      '${item.lineTotal.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: Responsive.fp(14),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ],
                ),
              )),
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
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.textSlate500, size: 24),
      ),
    );
  }

  // ─── FORM FIELDS (same as OrderFormScreen) ──────────────────

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
        Text(title,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: Responsive.fp(17),
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isLTR = false,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSlate300,
            fontSize: Responsive.fp(13),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: Responsive.sp(6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
          textAlign: isLTR ? TextAlign.left : TextAlign.right,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? AppColors.textSlate400 : AppColors.textPrimary,
            fontSize: Responsive.fp(14),
            fontFamily: isLTR ? 'Space Grotesk' : null,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSlate500,
              fontSize: Responsive.fp(13),
              fontFamily: isLTR ? 'Space Grotesk' : null,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12, left: 8),
              child: Icon(icon, color: AppColors.textSlate400, size: 20),
            ),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.sp(16),
              vertical: Responsive.sp(14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.primaryLight, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWilayaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الولاية',
          style: TextStyle(
            color: AppColors.textSlate300,
            fontSize: Responsive.fp(13),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: Responsive.sp(6)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoadingWilayas
              ? Padding(
                  padding: EdgeInsets.all(Responsive.sp(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: Responsive.sp(10)),
                      Text(
                        'جاري تحميل الولايات...',
                        style: TextStyle(
                            color: AppColors.textSlate400,
                            fontSize: Responsive.fp(13)),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<WilayaModel>(
                  value: _selectedWilaya,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textSlate400),
                  decoration: InputDecoration(
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12, left: 8),
                      child: Icon(Icons.location_city_outlined,
                          color: AppColors.textSlate400, size: 20),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.sp(16),
                      vertical: Responsive.sp(4),
                    ),
                    border: InputBorder.none,
                  ),
                  hint: Text(
                    'اختر الولاية',
                    style: TextStyle(
                        color: AppColors.textSlate500,
                        fontSize: Responsive.fp(13)),
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fp(14),
                  ),
                  dropdownColor: AppColors.surface,
                  items: _wilayas.map((w) {
                    return DropdownMenuItem<WilayaModel>(
                      value: w,
                      child: Text(
                        '${w.id} - ${w.name}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: Responsive.fp(14),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedWilaya = val);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildShippingTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع التوصيل',
          style: TextStyle(
            color: AppColors.textSlate300,
            fontSize: Responsive.fp(13),
            fontWeight: FontWeight.w500,
          ),
        ),
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
              _buildShippingOption('home', 'إلى المنزل', Icons.home_outlined),
              _buildShippingOption(
                  'desk', 'إلى المكتب', Icons.storefront_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingOption(String type, String label, IconData icon) {
    final isSelected = _shippingType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _shippingType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: Responsive.sp(12)),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Responsive.sp(18),
                color: isSelected ? Colors.white : AppColors.textSlate400,
              ),
              SizedBox(width: Responsive.sp(6)),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSlate400,
                  fontSize: Responsive.fp(13),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ORDER SUMMARY ──────────────────────────────────────────

  Widget _buildOrderSummary(CartProvider cart) {
    final subtotal = _cartSubtotal(cart);
    final total = _cartTotal(cart);

    return Container(
      padding: EdgeInsets.all(Responsive.sp(18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.cyan.withValues(alpha: 0.04),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Text(
                'ملخص الطلب',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary, size: Responsive.sp(20)),
            ],
          ),
          SizedBox(height: Responsive.sp(16)),
          Divider(
              color: AppColors.primary.withValues(alpha: 0.1), height: 1),
          SizedBox(height: Responsive.sp(14)),

          // Products subtotal
          _buildSummaryRow(
            'المنتجات (${cart.totalItems})',
            '${cart.items.length} منتج مختلف',
            '${subtotal.toStringAsFixed(0)} DA',
          ),
          SizedBox(height: Responsive.sp(10)),

          // Delivery price
          _buildSummaryRow(
            'سعر التوصيل${_shippingType == 'home' ? ' (منزل)' : ' (مكتب)'}',
            _selectedWilaya != null
                ? _selectedWilaya!.name
                : 'اختر الولاية',
            _selectedWilaya != null
                ? '${_deliveryPrice.toStringAsFixed(0)} DA'
                : '---',
          ),
          SizedBox(height: Responsive.sp(14)),
          Divider(
              color: AppColors.primary.withValues(alpha: 0.1), height: 1),
          SizedBox(height: Responsive.sp(14)),

          // Total
          Row(
            children: [
              Text(
                '${total.toStringAsFixed(0)} DA',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: Responsive.fp(22),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const Spacer(),
              Text(
                'الإجمالي',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String detail, String value) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: Responsive.fp(14),
            fontWeight: FontWeight.w600,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSlate300,
                fontSize: Responsive.fp(13),
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                color: AppColors.textSlate500,
                fontSize: Responsive.fp(11),
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON ──────────────────────────────────────────

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOrders,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تأكيد الطلبات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: Responsive.sp(8)),
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: Responsive.sp(20)),
                ],
              ),
      ),
    );
  }
}
