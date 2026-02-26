import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/wilaya_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/wilaya_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final WilayaService _wilayaService = WilayaService();

  int _sectionIndex = 0; // 0 = accounts, 1 = categories, 2 = products, 3 = orders, 4 = delivery settings
  int _typeIndex = 0; // 0 = gros, 1 = detail

  List<CategoryModel> _grosCategories = [];
  List<CategoryModel> _detailCategories = [];
  List<ProductModel> _grosProducts = [];
  List<ProductModel> _detailProducts = [];
  bool _isLoading = true;

  // Account management state
  List<Map<String, dynamic>> _allUsers = [];
  String _userFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  bool _isLoadingUsers = false;

  // Orders management state
  List<OrderModel> _allOrders = [];
  String _orderFilter = 'all'; // 'all', 'pending', 'confirmed', 'delivered', 'cancelled'
  bool _isLoadingOrders = false;
  String? _expandedOrderId;

  // Delivery settings state
  List<WilayaModel> _allWilayas = [];
  bool _isLoadingWilayas = false;

  @override
  void initState() {
    super.initState();
    _loadData();   // initial load of products/categories
    _loadUsers();  // initial load of users (since it's the default tab)
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final gros = await _categoryService.getCategories('gros').timeout(const Duration(seconds: 10));
      final detail = await _categoryService.getCategories('detail').timeout(const Duration(seconds: 10));
      final grosProd = await _productService.getAllProducts('gros').timeout(const Duration(seconds: 10));
      final detailProd = await _productService.getAllProducts('detail').timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _grosCategories = gros;
        _detailCategories = detail;
        _grosProducts = grosProd;
        _detailProducts = detailProd;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل البيانات');
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await AuthService().fetchAllUsers().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUsers = false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل المستخدمين');
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_userFilter == 'all') return _allUsers;
    return _allUsers.where((u) => u['status'] == _userFilter).toList();
  }

  List<OrderModel> get _filteredOrders {
    if (_orderFilter == 'all') return _allOrders;
    return _allOrders.where((o) => o.status == _orderFilter).toList();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _orderService.getAllOrders().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingOrders = false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل الطلبات');
    }
  }

  Future<void> _loadWilayas() async {
    setState(() => _isLoadingWilayas = true);
    try {
      await _wilayaService.seedWilayas(); // Seed if empty
      final wilayas = await _wilayaService.getAllWilayas().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _allWilayas = wilayas;
        _isLoadingWilayas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingWilayas = false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل الولايات');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _currentType => _typeIndex == 0 ? 'gros' : 'detail';

  List<CategoryModel> get _currentCategories =>
      _typeIndex == 0 ? _grosCategories : _detailCategories;

  List<ProductModel> get _currentProducts =>
      _typeIndex == 0 ? _grosProducts : _detailProducts;

  void _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  // ─── PICK IMAGE & CONVERT TO BASE64 ───────────────────────────

  Future<String?> _pickImageAsBase64(void Function(bool) setUploading) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // required for web
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) {
        _showErrorSnackBar('لم يتم تحميل الملف بشكل صحيح');
        return null;
      }

      // Check file size (limit to 1MB to keep RTDB reasonable)
      if (file.bytes!.length > 1024 * 1024) {
        _showErrorSnackBar('حجم الصورة كبير جداً. الحد الأقصى 1 ميجابايت');
        return null;
      }

      setUploading(true);

      // Convert to base64 data URI
      final ext = file.extension?.toLowerCase() ?? 'png';
      final mimeType = ext == 'jpg' || ext == 'jpeg'
          ? 'image/jpeg'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/png';
      final base64String = base64Encode(file.bytes!);
      final dataUri = 'data:$mimeType;base64,$base64String';

      setUploading(false);
      return dataUri;
    } catch (e) {
      debugPrint('Image pick error: $e');
      setUploading(false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل الصورة');
      return null;
    }
  }

  // ─── HELPER: DISPLAY IMAGE (URL or BASE64) ────────────────────

  Widget _buildImageWidget(String imageStr, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final fallback = errorWidget ?? const Icon(
      Icons.broken_image_outlined,
      color: AppColors.textSlate500,
      size: 28,
    );

    if (imageStr.startsWith('data:')) {
      try {
        // Extract base64 part from data URI
        final base64Part = imageStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else {
      return Image.network(
        imageStr,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
  }

  // ─── IMAGE PICKER WIDGET ──────────────────────────────────────

  Widget _buildImagePicker({
    required bool useUrl,
    required Function(bool) onToggle,
    required TextEditingController urlController,
    required String? uploadedUrl,
    required String? uploadedFileName,
    required bool isUploading,
    required Function(String url, String name) onUploaded,
    required Function(bool) setUploading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'صورة الفئة',
            style: TextStyle(
              color: AppColors.textSlate300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Toggle: URL vs Upload
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !useUrl ? AppColors.tabActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !useUrl
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 16,
                          color: !useUrl
                              ? AppColors.primaryDark
                              : AppColors.textSlate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'رفع صورة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !useUrl
                                ? AppColors.primaryDark
                                : AppColors.textSlate400,
                            fontSize: 13,
                            fontWeight:
                                !useUrl ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: useUrl ? AppColors.tabActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: useUrl
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link,
                          size: 16,
                          color:
                              useUrl ? AppColors.primaryDark : AppColors.textSlate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'رابط URL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: useUrl
                                ? AppColors.primaryDark
                                : AppColors.textSlate400,
                            fontSize: 13,
                            fontWeight:
                                useUrl ? FontWeight.bold : FontWeight.w500,
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
        const SizedBox(height: 12),

        // Content based on toggle
        if (useUrl)
          // URL text field
          TextField(
            controller: urlController,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Space Grotesk',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.textSlate500,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.image_outlined,
                    color: AppColors.textSlate400, size: 22),
              ),
              filled: true,
              fillColor: AppColors.surfaceDarkAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
            ),
          )
        else
          // Upload button + preview
          Column(
            children: [
              // Upload button
              GestureDetector(
                onTap: isUploading
                    ? null
                    : () async {
                        final url =
                            await _pickImageAsBase64(setUploading);
                        if (url != null) {
                          onUploaded(url, 'image_uploaded');
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: uploadedUrl != null
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.borderDark,
                      width: uploadedUrl != null ? 1.5 : 1,
                    ),
                  ),
                  child: isUploading
                      ? const Column(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'جاري رفع الصورة...',
                              style: TextStyle(
                                color: AppColors.textSlate400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : uploadedUrl != null
                          ? Column(
                              children: [
                                // Image preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImageWidget(
                                    uploadedUrl,
                                    width: 64,
                                    height: 64,
                                    errorWidget: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textSlate500,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade400,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'تم رفع الصورة بنجاح',
                                      style: TextStyle(
                                        color: AppColors.textSlate300,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'اضغط لتغيير الصورة',
                                  style: TextStyle(
                                    color: AppColors.textSlate500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    color: AppColors.textSlate400,
                                    size: 36),
                                SizedBox(height: 10),
                                Text(
                                  'اضغط لاختيار صورة من جهازك',
                                  style: TextStyle(
                                    color: AppColors.textSlate400,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'PNG, JPG, WEBP',
                                  style: TextStyle(
                                    color: AppColors.textSlate500,
                                    fontSize: 11,
                                    fontFamily: 'Space Grotesk',
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ─── ADD CATEGORY ─────────────────────────────────────────────

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final imageUrlController = TextEditingController();
    final orderController = TextEditingController();
    bool addToBoth = false;
    bool isSaving = false;
    bool useUrl = false; // default to upload
    bool isUploading = false;
    String? uploadedUrl;
    String? uploadedFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.textSlate500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    const Text(
                      'إضافة فئة جديدة',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name field
                    _buildTextField(
                      controller: nameController,
                      label: 'اسم الفئة',
                      hint: 'مثال: كابلات',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),
                    // Image picker (URL or Upload)
                    _buildImagePicker(
                      useUrl: useUrl,
                      onToggle: (val) =>
                          setSheetState(() => useUrl = val),
                      urlController: imageUrlController,
                      uploadedUrl: uploadedUrl,
                      uploadedFileName: uploadedFileName,
                      isUploading: isUploading,
                      onUploaded: (url, name) {
                        setSheetState(() {
                          uploadedUrl = url;
                          uploadedFileName = name;
                        });
                      },
                      setUploading: (val) =>
                          setSheetState(() => isUploading = val),
                    ),
                    const SizedBox(height: 16),
                    // Order field
                    _buildTextField(
                      controller: orderController,
                      label: 'الترتيب',
                      hint: '1',
                      icon: Icons.sort,
                      keyboardType: TextInputType.number,
                      isLTR: true,
                    ),
                    const SizedBox(height: 16),
                    // Add to both toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        children: [
                          Switch(
                            value: addToBoth,
                            onChanged: (v) =>
                                setSheetState(() => addToBoth = v),
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'إضافة لكلا النوعين (جملة + تجزئة)',
                              style: TextStyle(
                                color: AppColors.textSlate300,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (isSaving || isUploading)
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    _showErrorSnackBar('الرجاء إدخال اسم الفئة');
                                    return;
                                  }
                                  // Determine image URL
                                  final imageUrl = useUrl
                                      ? imageUrlController.text.trim()
                                      : (uploadedUrl ?? '');

                                  setSheetState(() => isSaving = true);
                                  try {
                                    final types = addToBoth
                                        ? ['gros', 'detail']
                                        : [_currentType];
                                    await _categoryService.addCategory(
                                      name: nameController.text.trim(),
                                      image: imageUrl,
                                      order: int.tryParse(
                                              orderController.text.trim()) ??
                                          0,
                                      types: types,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSuccessSnackBar('تمت إضافة الفئة بنجاح');
                                    _loadData();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showErrorSnackBar(
                                        'حدث خطأ أثناء إضافة الفئة');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'إضافة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── EDIT CATEGORY ────────────────────────────────────────────

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final imageUrlController = TextEditingController(text: category.image);
    final orderController =
        TextEditingController(text: category.order.toString());
    bool isSaving = false;
    // Default to URL mode if there is an existing image, upload mode if empty
    bool useUrl = category.image.isNotEmpty;
    bool isUploading = false;
    String? uploadedUrl;
    String? uploadedFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.textSlate500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    const Text(
                      'تعديل الفئة',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category ID badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.id,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name field
                    _buildTextField(
                      controller: nameController,
                      label: 'اسم الفئة',
                      hint: 'مثال: كابلات',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),
                    // Image picker (URL or Upload)
                    _buildImagePicker(
                      useUrl: useUrl,
                      onToggle: (val) =>
                          setSheetState(() => useUrl = val),
                      urlController: imageUrlController,
                      uploadedUrl: uploadedUrl,
                      uploadedFileName: uploadedFileName,
                      isUploading: isUploading,
                      onUploaded: (url, name) {
                        setSheetState(() {
                          uploadedUrl = url;
                          uploadedFileName = name;
                        });
                      },
                      setUploading: (val) =>
                          setSheetState(() => isUploading = val),
                    ),
                    const SizedBox(height: 16),
                    // Order field
                    _buildTextField(
                      controller: orderController,
                      label: 'الترتيب',
                      hint: '1',
                      icon: Icons.sort,
                      keyboardType: TextInputType.number,
                      isLTR: true,
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (isSaving || isUploading)
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    _showErrorSnackBar('الرجاء إدخال اسم الفئة');
                                    return;
                                  }
                                  // Determine image URL
                                  final imageUrl = useUrl
                                      ? imageUrlController.text.trim()
                                      : (uploadedUrl ??
                                          category.image); // keep old if not changed

                                  setSheetState(() => isSaving = true);
                                  try {
                                    await _categoryService.updateCategory(
                                      shoppingType: _currentType,
                                      categoryId: category.id,
                                      name: nameController.text.trim(),
                                      image: imageUrl,
                                      order: int.tryParse(
                                              orderController.text.trim()) ??
                                          0,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSuccessSnackBar(
                                        'تم تعديل الفئة بنجاح');
                                    _loadData();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showErrorSnackBar(
                                        'حدث خطأ أثناء تعديل الفئة');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_outlined,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'حفظ التعديلات',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── DELETE CATEGORY ──────────────────────────────────────────

  void _showDeleteConfirmation(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'تأكيد الحذف',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textSlate300,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                            text: 'هل أنت متأكد من حذف الفئة\n'),
                        TextSpan(
                          text: '«${category.name}»',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '؟'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'لا يمكن التراجع عن هذا الإجراء',
                    style: TextStyle(
                      color: AppColors.textSlate500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.borderDark),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: AppColors.textSlate300,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await _categoryService.deleteCategory(
                              shoppingType: _currentType,
                              categoryId: category.id,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSuccessSnackBar('تم حذف الفئة بنجاح');
                            _loadData();
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            _showErrorSnackBar('حدث خطأ أثناء حذف الفئة');
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  // ─── REUSABLE TEXT FIELD ──────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isLTR = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSlate300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
          textAlign: isLTR ? TextAlign.left : TextAlign.right,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: isLTR ? 'Space Grotesk' : null,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: isLTR ? 'Space Grotesk' : null,
              color: AppColors.textSlate500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: AppColors.textSlate400, size: 22),
            ),
            filled: true,
            fillColor: AppColors.surfaceDarkAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
          ),
        ),
      ],
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────

  // Build sidebar content (reused in both inline sidebar and drawer)
  Widget _buildSidebarContent({bool isDrawer = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 24, bottom: 24, right: isDrawer ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarSection(
            title: 'إدارة الحسابات',
            icon: Icons.people,
            sectionIndex: 0,
            closeDrawer: isDrawer,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          _buildSidebarSection(
            title: 'الفئات',
            icon: Icons.category,
            sectionIndex: 1,
            closeDrawer: isDrawer,
          ),
          if (_sectionIndex == 1) _buildSidebarSubItems(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          _buildSidebarSection(
            title: 'المنتجات',
            icon: Icons.inventory_2,
            sectionIndex: 2,
            closeDrawer: isDrawer,
          ),
          if (_sectionIndex == 2) _buildSidebarSubItems(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          _buildSidebarSection(
            title: 'إدارة الطلبات',
            icon: Icons.receipt_long,
            sectionIndex: 3,
            closeDrawer: isDrawer,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          _buildSidebarSection(
            title: 'إعدادات التوصيل',
            icon: Icons.local_shipping,
            sectionIndex: 4,
            closeDrawer: isDrawer,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isWide = Responsive.screenWidth >= Breakpoints.tablet;

    return Scaffold(
      // Drawer for narrow screens
      endDrawer: isWide ? null : Drawer(
        backgroundColor: AppColors.surfaceAlt,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.textSlate400, size: Responsive.sp(22)),
                    ),
                    const Spacer(),
                    Text('القائمة', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(18), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(child: _buildSidebarContent(isDrawer: true)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: Responsive.sp(300),
              height: Responsive.sp(300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: Responsive.sp(250),
              height: Responsive.sp(250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── HEADER ──
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(16)),
                  child: Row(
                    children: [
                      // Logout button
                      _buildIconButton(
                        icon: Icons.logout,
                        color: Colors.red,
                        bgColor: Colors.red.withValues(alpha: 0.1),
                        onTap: _handleLogout,
                      ),
                      // Hamburger menu on narrow screens
                      if (!isWide) ...[
                        const SizedBox(width: 8),
                        Builder(
                          builder: (ctx) => _buildIconButton(
                            icon: Icons.menu,
                            color: AppColors.textPrimary,
                            bgColor: AppColors.surfaceAlt,
                            onTap: () => Scaffold.of(ctx).openEndDrawer(),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'لوحة التحكم',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: Responsive.fp(24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: Responsive.sp(2)),
                          Text(
                            'إدارة الفئات والمنتجات والحسابات',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: Responsive.fp(13),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: Responsive.sp(12)),
                      // Admin avatar
                      Container(
                        width: Responsive.sp(44),
                        height: Responsive.sp(44),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.cyan],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: Responsive.sp(22)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── SIDEBAR (only on wide screens) ──
                      if (isWide)
                        Container(
                          width: 240,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceAlt,
                            border: Border(
                              left: BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                          child: _buildSidebarContent(),
                        ),
                      
                      // ── MAIN CONTENT ──
                      Expanded(
                        child: Column(
                          children: [
                            if (_sectionIndex == 0)
                              Expanded(child: _buildAccountManagerView())
                            else if (_sectionIndex == 3)
                              Expanded(child: _buildOrdersManagerView())
                            else if (_sectionIndex == 4)
                              Expanded(child: _buildDeliverySettingsView())
                            else ...[
                              // ── ITEM COUNT ──
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(8)),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: Responsive.sp(10), vertical: Responsive.sp(5)),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_sectionIndex == 1 ? _currentCategories.length : _currentProducts.length}',
                                        style: TextStyle(color: AppColors.primaryLight, fontSize: Responsive.fp(13), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_sectionIndex == 1 ? 'الفئات' : 'المنتجات'} - ${_typeIndex == 0 ? 'بالجملة' : 'بالتجزئة'}',
                                      style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),

                              // ── LIST ──
                              Expanded(
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                    : _sectionIndex == 1
                                        ? _buildCategoryList(_currentCategories)
                                        : _buildProductList(_currentProducts),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ── FAB ──
      floatingActionButton: (_sectionIndex == 1 || _sectionIndex == 2 || _sectionIndex == 4) ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _sectionIndex == 1
              ? _showAddCategoryDialog
              : _sectionIndex == 4
                  ? _showAddWilayaDialog
                  : _showAddProductDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add, color: Colors.white, size: Responsive.sp(20)),
          label: Text(
            _sectionIndex == 1 ? 'إضافة فئة' : _sectionIndex == 4 ? 'إضافة ولاية' : 'إضافة منتج',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fp(14),
            ),
          ),
        ),
      ) : null,
    );
  }

  // ─── CATEGORY LIST WIDGET ─────────────────────────────────────

  Widget _buildCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                color: AppColors.textSlate500, size: 56),
            const SizedBox(height: 16),
            const Text(
              'لا توجد فئات',
              style: TextStyle(
                color: AppColors.textSlate400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على + لإضافة فئة جديدة',
              style: TextStyle(
                color: AppColors.textSlate500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildCategoryItem(cat, index);
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.surface,
              child: category.image.isNotEmpty
                  ? _buildImageWidget(category.image, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: AppColors.textSlate500, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('الترتيب: ${category.order}', style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(category.id, style: const TextStyle(color: AppColors.textSlate500, fontSize: 11, fontFamily: 'Space Grotesk')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Action buttons
          Column(
            children: [
              _buildSmallButton(icon: Icons.edit_outlined, color: AppColors.primary, onTap: () => _showEditCategoryDialog(category)),
              const SizedBox(height: 8),
              _buildSmallButton(icon: Icons.delete_outline, color: Colors.red, onTap: () => _showDeleteConfirmation(category)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT LIST WIDGET ──────────────────────────────────────

  Widget _buildProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.textSlate500, size: 56),
            const SizedBox(height: 16),
            const Text('لا توجد منتجات', style: TextStyle(color: AppColors.textSlate400, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('اضغط على + لإضافة منتج جديد', style: TextStyle(color: AppColors.textSlate500, fontSize: 13)),
          ],
        ),
      );
    }

    final categories = _currentCategories;
    
    // Create a map of categoryId -> list of products
    final Map<String, List<ProductModel>> productsByCategory = {};
    for (var cat in categories) {
      productsByCategory[cat.id] = [];
    }
    
    final List<ProductModel> uncategorized = [];
    for (var product in products) {
      if (productsByCategory.containsKey(product.categoryId)) {
        productsByCategory[product.categoryId]!.add(product);
      } else {
        uncategorized.add(product);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        children: [
          for (var cat in categories)
            if ((productsByCategory[cat.id] ?? []).isNotEmpty)
              _buildCategoryExpansionTile(cat, productsByCategory[cat.id]!),
          if (uncategorized.isNotEmpty)
            _buildCategoryExpansionTile(
              CategoryModel(id: 'uncategorized', name: 'غير مصنف', image: '', order: 999), 
              uncategorized,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryExpansionTile(CategoryModel category, List<ProductModel> categoryProducts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSlate400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (category.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 40, height: 40,
                    child: _buildImageWidget(category.image, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.category_outlined, color: AppColors.textSlate500, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  textAlign: TextAlign.start,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${categoryProducts.length}',
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
              child: Column(
                children: categoryProducts.map((p) => _buildProductItem(p, isInsideCard: true)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(ProductModel product, {bool isInsideCard = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInsideCard ? AppColors.surface : AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.surface,
              child: product.image.isNotEmpty
                  ? _buildImageWidget(product.image, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: AppColors.textSlate500, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isAvailable ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isAvailable ? 'متوفر' : 'غير متوفر',
                        style: TextStyle(color: product.isAvailable ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الكمية: ${product.quantity}',
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.price.toStringAsFixed(0)} د.ج',
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(product.categoryId, style: const TextStyle(color: AppColors.textSlate500, fontSize: 11, fontFamily: 'Space Grotesk')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Action buttons
          Column(
            children: [
              _buildSmallButton(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: () => _showEditProductDialog(product),
              ),
              const SizedBox(height: 8),
              _buildSmallButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () => _showDeleteProductConfirmation(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ADD PRODUCT ────────────────────────────────────────────────

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final imageUrlController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final quantityController = TextEditingController(text: '0');
    String? selectedCategoryId;
    bool isSaving = false;
    bool useUrl = false;
    bool isUploading = false;
    String? uploadedUrl;
    String? uploadedFileName;

    final categories = _currentCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.textSlate500, borderRadius: BorderRadius.circular(2))),
                    const Text('إضافة منتج جديد', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildTextField(controller: nameController, label: 'اسم المنتج', hint: 'مثال: كابل USB-C', icon: Icons.inventory_2_outlined),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      useUrl: useUrl,
                      onToggle: (val) => setSheetState(() => useUrl = val),
                      urlController: imageUrlController,
                      uploadedUrl: uploadedUrl,
                      uploadedFileName: uploadedFileName,
                      isUploading: isUploading,
                      onUploaded: (url, name) => setSheetState(() { uploadedUrl = url; uploadedFileName = name; }),
                      setUploading: (val) => setSheetState(() => isUploading = val),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: priceController, label: 'السعر (د.ج)', hint: '350', icon: Icons.attach_money, keyboardType: TextInputType.number, isLTR: true),
                    const SizedBox(height: 16),
                    _buildTextField(controller: descController, label: 'الوصف', hint: 'وصف المنتج...', icon: Icons.description_outlined),
                    const SizedBox(height: 16),
                    // Category dropdown
                    Align(alignment: Alignment.centerRight, child: const Text('الفئة', style: TextStyle(color: AppColors.textSlate300, fontSize: 14, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceDarkAlt,
                          hint: const Text('اختر الفئة', style: TextStyle(color: AppColors.textSlate500, fontSize: 14)),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                          onChanged: (val) => setSheetState(() => selectedCategoryId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quantity input
                    _buildTextField(controller: quantityController, label: 'الكمية', hint: '0', icon: Icons.inventory_outlined, keyboardType: TextInputType.number, isLTR: true),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.primary, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))]),
                        child: ElevatedButton(
                          onPressed: (isSaving || isUploading) ? null : () async {
                            if (nameController.text.trim().isEmpty) { _showErrorSnackBar('الرجاء إدخال اسم المنتج'); return; }
                            if (selectedCategoryId == null) { _showErrorSnackBar('الرجاء اختيار الفئة'); return; }
                            final imageUrl = useUrl ? imageUrlController.text.trim() : (uploadedUrl ?? '');
                            setSheetState(() => isSaving = true);
                            try {
                              await _productService.addProduct(
                                shoppingType: _currentType,
                                categoryId: selectedCategoryId!,
                                name: nameController.text.trim(),
                                image: imageUrl,
                                price: double.tryParse(priceController.text.trim()) ?? 0,
                                description: descController.text.trim(),
                                quantity: int.tryParse(quantityController.text.trim()) ?? 0,
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                              _showSuccessSnackBar('تمت إضافة المنتج بنجاح');
                              _loadData();
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              _showErrorSnackBar('حدث خطأ أثناء إضافة المنتج');
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white, size: 20), SizedBox(width: 8), Text('إضافة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── EDIT PRODUCT ───────────────────────────────────────────────

  void _showEditProductDialog(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final imageUrlController = TextEditingController(text: product.image);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final descController = TextEditingController(text: product.description);
    final quantityController = TextEditingController(text: product.quantity.toString());
    bool isSaving = false;
    bool useUrl = product.image.isNotEmpty;
    bool isUploading = false;
    String? uploadedUrl;
    String? uploadedFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.textSlate500, borderRadius: BorderRadius.circular(2))),
                    const Text('تعديل المنتج', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(product.id, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(controller: nameController, label: 'اسم المنتج', hint: 'مثال: كابل USB-C', icon: Icons.inventory_2_outlined),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      useUrl: useUrl,
                      onToggle: (val) => setSheetState(() => useUrl = val),
                      urlController: imageUrlController,
                      uploadedUrl: uploadedUrl,
                      uploadedFileName: uploadedFileName,
                      isUploading: isUploading,
                      onUploaded: (url, name) => setSheetState(() { uploadedUrl = url; uploadedFileName = name; }),
                      setUploading: (val) => setSheetState(() => isUploading = val),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: priceController, label: 'السعر (د.ج)', hint: '350', icon: Icons.attach_money, keyboardType: TextInputType.number, isLTR: true),
                    const SizedBox(height: 16),
                    _buildTextField(controller: descController, label: 'الوصف', hint: 'وصف المنتج...', icon: Icons.description_outlined),
                    const SizedBox(height: 16),
                    // Category (read-only display)
                    Align(alignment: Alignment.centerRight, child: const Text('الفئة', style: TextStyle(color: AppColors.textSlate300, fontSize: 14, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceDarkAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
                      child: Text(product.categoryId, style: const TextStyle(color: AppColors.textSlate400, fontSize: 14, fontFamily: 'Space Grotesk')),
                    ),
                    const SizedBox(height: 16),
                    // Quantity input
                    _buildTextField(controller: quantityController, label: 'الكمية', hint: '0', icon: Icons.inventory_outlined, keyboardType: TextInputType.number, isLTR: true),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.primary, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))]),
                        child: ElevatedButton(
                          onPressed: (isSaving || isUploading) ? null : () async {
                            if (nameController.text.trim().isEmpty) { _showErrorSnackBar('الرجاء إدخال اسم المنتج'); return; }
                            final imageUrl = useUrl ? imageUrlController.text.trim() : (uploadedUrl ?? product.image);
                            setSheetState(() => isSaving = true);
                            try {
                              await _productService.updateProduct(
                                shoppingType: _currentType,
                                categoryId: product.categoryId,
                                productId: product.id,
                                name: nameController.text.trim(),
                                image: imageUrl,
                                price: double.tryParse(priceController.text.trim()) ?? 0,
                                description: descController.text.trim(),
                                quantity: int.tryParse(quantityController.text.trim()) ?? 0,
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                              _showSuccessSnackBar('تم تعديل المنتج بنجاح');
                              _loadData();
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              _showErrorSnackBar('حدث خطأ أثناء تعديل المنتج');
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_outlined, color: Colors.white, size: 20), SizedBox(width: 8), Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── DELETE PRODUCT ─────────────────────────────────────────────

  void _showDeleteProductConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Expanded(child: Text('تأكيد الحذف', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textSlate300, fontSize: 15, height: 1.6),
                      children: [
                        const TextSpan(text: 'هل أنت متأكد من حذف المنتج\n'),
                        TextSpan(text: '«${product.name}»', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        const TextSpan(text: '؟'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('لا يمكن التراجع عن هذا الإجراء', style: TextStyle(color: AppColors.textSlate500, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderDark))),
                  child: const Text('إلغاء', style: TextStyle(color: AppColors.textSlate300, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    setDialogState(() => isDeleting = true);
                    try {
                      await _productService.deleteProduct(shoppingType: _currentType, categoryId: product.categoryId, productId: product.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showSuccessSnackBar('تم حذف المنتج بنجاح');
                      _loadData();
                    } catch (e) {
                      setDialogState(() => isDeleting = false);
                      _showErrorSnackBar('حدث خطأ أثناء حذف المنتج');
                    }
                  },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), backgroundColor: Colors.red.withValues(alpha: 0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                      : const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── ORDERS MANAGEMENT VIEW ────────────────────────────────────

  Widget _buildOrdersManagerView() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // Filter tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(8)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOrderFilterChip('الكل', 'all'),
                  SizedBox(width: Responsive.sp(8)),
                  _buildOrderFilterChip('قيد الانتظار', 'pending'),
                  SizedBox(width: Responsive.sp(8)),
                  _buildOrderFilterChip('مؤكد', 'confirmed'),
                  SizedBox(width: Responsive.sp(8)),
                  _buildOrderFilterChip('تم التوصيل', 'delivered'),
                  SizedBox(width: Responsive.sp(8)),
                  _buildOrderFilterChip('ملغي', 'cancelled'),
                ],
              ),
            ),
          ),
          // Refresh button + count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(4)),
            child: Row(
              children: [
                Text(
                  'إدارة الطلبات',
                  style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14), fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.sp(10), vertical: Responsive.sp(5)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_filteredOrders.length}',
                    style: TextStyle(color: AppColors.primaryLight, fontSize: Responsive.fp(13), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                  ),
                ),
                SizedBox(width: Responsive.sp(8)),
                IconButton(
                  onPressed: _loadOrders,
                  icon: Icon(Icons.refresh, color: AppColors.primary, size: Responsive.sp(20)),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: _isLoadingOrders
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, color: AppColors.textSlate500, size: Responsive.sp(48)),
                            SizedBox(height: Responsive.sp(12)),
                            Text('لا توجد طلبات', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(16))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(8)),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (ctx, i) => _buildOrderCard(_filteredOrders[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFilterChip(String label, String value) {
    final isSelected = _orderFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _orderFilter = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.sp(14), vertical: Responsive.sp(8)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSlate400,
            fontSize: Responsive.fp(13),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'قيد الانتظار';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'مؤكد';
        icon = Icons.check_circle_outline;
        break;
      case 'delivered':
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        label = 'تم التوصيل';
        icon = Icons.local_shipping;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        label = 'ملغي';
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = AppColors.surfaceAlt;
        textColor = AppColors.textSlate400;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.sp(10), vertical: Responsive.sp(5)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          SizedBox(width: Responsive.sp(4)),
          Text(label, style: TextStyle(color: textColor, fontSize: Responsive.fp(12), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isExpanded = _expandedOrderId == order.orderId;
    final date = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.sp(10)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order header (tappable)
          InkWell(
            onTap: () {
              setState(() {
                _expandedOrderId = isExpanded ? null : order.orderId;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.all(Responsive.sp(14)),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Customer name (right in RTL)
                      Flexible(
                        child: Text(
                          order.customerFullName,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(14), fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(11), fontFamily: 'Space Grotesk'),
                      ),
                      SizedBox(width: Responsive.sp(8)),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  SizedBox(height: Responsive.sp(8)),
                  Row(
                    children: [
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSlate400, size: 20),
                      SizedBox(width: Responsive.sp(4)),
                      Flexible(
                        child: Text(
                          order.productName,
                          style: TextStyle(color: AppColors.textSlate300, fontSize: Responsive.fp(13)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text('×${order.quantity}', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(12), fontFamily: 'Space Grotesk')),
                      SizedBox(width: Responsive.sp(8)),
                      Text(
                        '${order.totalPrice.toStringAsFixed(0)} DA',
                        style: TextStyle(color: AppColors.primaryLight, fontSize: Responsive.fp(14), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (isExpanded) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: EdgeInsets.all(Responsive.sp(14)),
              child: Column(
                children: [
                  _buildOrderDetailRow('رقم الطلب', order.orderId),
                  _buildOrderDetailRow('الهاتف', order.phone),
                  _buildOrderDetailRow('الولاية', order.wilaya),
                  _buildOrderDetailRow('العنوان', order.address),
                  _buildOrderDetailRow('نوع التوصيل', order.shippingType == 'home' ? 'إلى المنزل' : 'إلى المكتب'),
                  _buildOrderDetailRow('سعر المنتج', '${order.productPrice.toStringAsFixed(0)} DA'),
                  _buildOrderDetailRow('الكمية', '${order.quantity}'),
                  _buildOrderDetailRow('سعر التوصيل', '${order.deliveryPrice.toStringAsFixed(0)} DA'),
                  _buildOrderDetailRow('الإجمالي', '${order.totalPrice.toStringAsFixed(0)} DA', isBold: true),
                  SizedBox(height: Responsive.sp(16)),
                  // Action buttons — same style as user management buttons
                  Wrap(
                    spacing: Responsive.sp(8),
                    runSpacing: Responsive.sp(8),
                    alignment: WrapAlignment.center,
                    children: [
                      if (order.status == 'pending')
                        _buildPremiumActionButton(
                          label: 'تأكيد',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                          onTap: () => _updateOrderStatus(order.orderId, 'confirmed'),
                          isPrimary: true,
                        ),
                      if (order.status == 'confirmed')
                        _buildPremiumActionButton(
                          label: 'تم التوصيل',
                          icon: Icons.local_shipping,
                          color: AppColors.primary,
                          onTap: () => _updateOrderStatus(order.orderId, 'delivered'),
                          isPrimary: true,
                        ),
                      if (order.status != 'cancelled' && order.status != 'delivered')
                        _buildPremiumActionButton(
                          label: 'إلغاء',
                          icon: Icons.cancel,
                          color: AppColors.error,
                          onTap: () => _updateOrderStatus(order.orderId, 'cancelled'),
                        ),
                      _buildPremiumActionButton(
                        label: 'حذف',
                        icon: Icons.delete_outline,
                        color: Colors.red.shade700,
                        onTap: () => _deleteOrder(order.orderId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.sp(4)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(13)),
          ),
          SizedBox(width: Responsive.sp(12)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isBold ? AppColors.primaryDark : AppColors.textPrimary,
                fontSize: Responsive.fp(13),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Space Grotesk',
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      _showSuccessSnackBar('تم تحديث حالة الطلب');
      _loadOrders();
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء تحديث حالة الطلب');
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Expanded(
                    child: Text('تأكيد حذف الطلب', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                ],
              ),
              content: const Text('هل أنت متأكد من حذف هذا الطلب نهائياً؟', style: TextStyle(color: AppColors.textSlate300, fontSize: 15), textAlign: TextAlign.center),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderDark))),
                  child: const Text('إلغاء', style: TextStyle(color: AppColors.textSlate300, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await _orderService.deleteOrder(orderId);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSuccessSnackBar('تم حذف الطلب');
                            _loadOrders();
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            _showErrorSnackBar('حدث خطأ أثناء حذف الطلب');
                          }
                        },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), backgroundColor: Colors.red.withValues(alpha: 0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                      : const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── DELIVERY SETTINGS VIEW ────────────────────────────────────

  Widget _buildDeliverySettingsView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(8)),
          child: Row(
            children: [
              IconButton(
                onPressed: _loadWilayas,
                icon: Icon(Icons.refresh, color: AppColors.primary, size: Responsive.sp(20)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.sp(10), vertical: Responsive.sp(5)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_allWilayas.length}',
                  style: TextStyle(color: AppColors.primaryLight, fontSize: Responsive.fp(13), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                ),
              ),
              const Spacer(),
              Text(
                'إعدادات التوصيل - الولايات',
                style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Wilayas list
        Expanded(
          child: _isLoadingWilayas
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _allWilayas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, color: AppColors.textSlate500, size: Responsive.sp(48)),
                          SizedBox(height: Responsive.sp(12)),
                          Text('لا توجد ولايات', style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(16))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding, vertical: Responsive.sp(8)),
                      itemCount: _allWilayas.length,
                      itemBuilder: (ctx, i) => _buildWilayaCard(_allWilayas[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildWilayaCard(WilayaModel wilaya) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.sp(8)),
      padding: EdgeInsets.all(Responsive.sp(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: wilaya.isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle active
              Switch(
                value: wilaya.isActive,
                onChanged: (val) async {
                  try {
                    await _wilayaService.toggleWilaya(wilaya.id, val);
                    _loadWilayas();
                  } catch (e) {
                    _showErrorSnackBar('حدث خطأ');
                  }
                },
                activeColor: AppColors.primary,
              ),
              // Edit
              IconButton(
                onPressed: () => _showEditWilayaDialog(wilaya),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Delete
              IconButton(
                onPressed: () => _deleteWilaya(wilaya),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const Spacer(),
          // Prices
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${wilaya.homeDeliveryPrice.toStringAsFixed(0)} DA', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(12), fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600)),
                  SizedBox(width: Responsive.sp(4)),
                  Icon(Icons.home_outlined, color: AppColors.textSlate400, size: 14),
                ],
              ),
              SizedBox(height: Responsive.sp(2)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${wilaya.deskDeliveryPrice.toStringAsFixed(0)} DA', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(12), fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600)),
                  SizedBox(width: Responsive.sp(4)),
                  Icon(Icons.storefront_outlined, color: AppColors.textSlate400, size: 14),
                ],
              ),
            ],
          ),
          SizedBox(width: Responsive.sp(12)),
          // Name + ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  wilaya.name,
                  style: TextStyle(
                    color: wilaya.isActive ? AppColors.textPrimary : AppColors.textSlate500,
                    fontSize: Responsive.fp(14),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                Text(
                  wilaya.id,
                  style: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(11), fontFamily: 'Space Grotesk'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWilayaDialog() {
    final nameController = TextEditingController();
    final homeController = TextEditingController(text: '600');
    final deskController = TextEditingController(text: '400');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.textSlate500, borderRadius: BorderRadius.circular(2))),
                    const Text('إضافة ولاية جديدة', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildTextField(controller: nameController, label: 'اسم الولاية', hint: 'مثال: الجزائر', icon: Icons.location_city),
                    const SizedBox(height: 16),
                    _buildTextField(controller: homeController, label: 'سعر التوصيل للمنزل', hint: '600', icon: Icons.home_outlined, isLTR: true, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(controller: deskController, label: 'سعر التوصيل للمكتب', hint: '400', icon: Icons.storefront_outlined, isLTR: true, keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.primary),
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    _showErrorSnackBar('الرجاء إدخال اسم الولاية');
                                    return;
                                  }
                                  setSheetState(() => isSaving = true);
                                  try {
                                    await _wilayaService.addWilaya(
                                      name: nameController.text.trim(),
                                      homeDeliveryPrice: double.tryParse(homeController.text) ?? 600,
                                      deskDeliveryPrice: double.tryParse(deskController.text) ?? 400,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSuccessSnackBar('تمت إضافة الولاية بنجاح');
                                    _loadWilayas();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showErrorSnackBar('حدث خطأ');
                                  }
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white, size: 20), SizedBox(width: 8), Text('إضافة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditWilayaDialog(WilayaModel wilaya) {
    final nameController = TextEditingController(text: wilaya.name);
    final homeController = TextEditingController(text: wilaya.homeDeliveryPrice.toStringAsFixed(0));
    final deskController = TextEditingController(text: wilaya.deskDeliveryPrice.toStringAsFixed(0));
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.textSlate500, borderRadius: BorderRadius.circular(2))),
                    const Text('تعديل الولاية', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(wilaya.id, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontFamily: 'Space Grotesk', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(controller: nameController, label: 'اسم الولاية', hint: 'اسم الولاية', icon: Icons.location_city),
                    const SizedBox(height: 16),
                    _buildTextField(controller: homeController, label: 'سعر التوصيل للمنزل', hint: '600', icon: Icons.home_outlined, isLTR: true, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(controller: deskController, label: 'سعر التوصيل للمكتب', hint: '400', icon: Icons.storefront_outlined, isLTR: true, keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.primary),
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    _showErrorSnackBar('الرجاء إدخال اسم الولاية');
                                    return;
                                  }
                                  setSheetState(() => isSaving = true);
                                  try {
                                    await _wilayaService.updateWilaya(
                                      wilayaId: wilaya.id,
                                      name: nameController.text.trim(),
                                      homeDeliveryPrice: double.tryParse(homeController.text) ?? 600,
                                      deskDeliveryPrice: double.tryParse(deskController.text) ?? 400,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSuccessSnackBar('تم تعديل الولاية بنجاح');
                                    _loadWilayas();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showErrorSnackBar('حدث خطأ');
                                  }
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save, color: Colors.white, size: 20), SizedBox(width: 8), Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteWilaya(WilayaModel wilaya) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Expanded(child: Text('تأكيد حذف الولاية', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                ],
              ),
              content: Text('هل أنت متأكد من حذف «${wilaya.name}»؟', style: const TextStyle(color: AppColors.textSlate300, fontSize: 15), textAlign: TextAlign.center),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderDark))),
                  child: const Text('إلغاء', style: TextStyle(color: AppColors.textSlate300, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await _wilayaService.deleteWilaya(wilaya.id);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSuccessSnackBar('تم حذف الولاية');
                            _loadWilayas();
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            _showErrorSnackBar('حدث خطأ أثناء حذف الولاية');
                          }
                        },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), backgroundColor: Colors.red.withValues(alpha: 0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                      : const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── SIDEBAR UTILITY WIDGETS ──────────────────────────────────

  Widget _buildSidebarSection({required String title, required IconData icon, required int sectionIndex, bool closeDrawer = false}) {
    final isSelected = _sectionIndex == sectionIndex;
    return InkWell(
      onTap: () {
        setState(() => _sectionIndex = sectionIndex);
        if (sectionIndex == 0 && _allUsers.isEmpty) {
          _loadUsers();
        }
        if (sectionIndex == 3 && _allOrders.isEmpty) {
          _loadOrders();
        }
        if (sectionIndex == 4 && _allWilayas.isEmpty) {
          _loadWilayas();
        }
        if (closeDrawer && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSlate400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryDark : AppColors.textSlate300,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSubItems() {
    return Column(
      children: [
        _buildSidebarSubItem(title: 'بالجملة', typeIndex: 0),
        _buildSidebarSubItem(title: 'بالتجزئة', typeIndex: 1),
      ],
    );
  }

  Widget _buildSidebarSubItem({required String title, required int typeIndex}) {
    final isSelected = _typeIndex == typeIndex;
    return InkWell(
      onTap: () => setState(() => _typeIndex = typeIndex),
      child: Container(
        padding: const EdgeInsets.only(right: 48, left: 16, top: 10, bottom: 10),
        color: isSelected ? AppColors.surfaceDark : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.textSlate500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryLight : AppColors.textSlate400,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SMALL UTILITY WIDGETS ────────────────────────────────────

  Widget _buildSmallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── ACCOUNT MANAGER VIEW ─────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccountManagerView() {
    return Column(
      children: [
        // ── Filter chips ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('الكل', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('قيد المراجعة', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('مفعّل', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('مرفوض', 'rejected'),
              const Spacer(),
              // Refresh button
              InkWell(
                onTap: _loadUsers,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // User count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredUsers.length}',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Space Grotesk',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── User list ──
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: AppColors.textSlate500, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'لا يوجد مستخدمون',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceDark,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _userFilter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _userFilter = filterValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = user['status'] ?? 'pending';
    final statusColor = status == 'approved'
        ? AppColors.success
        : status == 'rejected'
            ? AppColors.error
            : AppColors.warning;
    final statusLabel = status == 'approved'
        ? 'مفعّل'
        : status == 'rejected'
            ? 'مرفوض'
            : 'قيد المراجعة';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top colored accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(color: statusColor.withValues(alpha: 0.8)),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER: Avatar, Name, Email, Status ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large premium avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.cyan.withValues(alpha: 0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (user['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name & Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'مستخدم بدون اسم',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user['email'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textSlate500,
                                fontSize: 14,
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status floating pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: AppColors.surfaceAlt, height: 1),
                  ),

                  // ── INFO SECTION ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        if ((user['storeName'] ?? '').toString().isNotEmpty)
                          _buildDetailRow(Icons.storefront_outlined, 'اسم المتجر', user['storeName']),
                        if ((user['phone'] ?? '').toString().isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: AppColors.borderDark),
                          ),
                          _buildDetailRow(Icons.phone_outlined, 'رقم الهاتف', user['phone'], isEnglish: true),
                        ],
                        if ((user['wilaya'] ?? '').toString().isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: AppColors.borderDark),
                          ),
                          _buildDetailRow(Icons.location_on_outlined, 'الولاية', user['wilaya']),
                        ],
                      ],
                    ),
                  ),

                  // ── ACTION BUTTONS ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (status != 'approved')
                        Expanded(
                          child: _buildPremiumActionButton(
                            label: 'تفعيل',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            isPrimary: true,
                            onTap: () => _updateUserStatus(user['uid'], 'approved'),
                          ),
                        ),
                      if (status != 'approved' && status != 'rejected') const SizedBox(width: 12),
                      if (status != 'rejected')
                        Expanded(
                          child: _buildPremiumActionButton(
                            label: 'رفض',
                            icon: Icons.block,
                            color: AppColors.warning,
                            isPrimary: false,
                            onTap: () => _updateUserStatus(user['uid'], 'rejected'),
                          ),
                        ),
                      const SizedBox(width: 12),                      Expanded(
                        child: _buildPremiumActionButton(
                          label: 'حذف',
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          isPrimary: false,
                          onTap: () => _showDeleteUserConfirmation(user),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isEnglish = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSlate500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: isEnglish ? 'Space Grotesk' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isIconOnly = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 14, 
            horizontal: isIconOnly ? 14 : 20
          ),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 20, 
                color: isPrimary ? Colors.white : color
              ),
              if (!isIconOnly) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(String uid, String newStatus) async {
    try {
      await AuthService().updateUserStatus(uid, newStatus);
      _showSuccessSnackBar(
        newStatus == 'approved' ? 'تم تفعيل الحساب بنجاح' : 'تم رفض الحساب',
      );
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء تحديث حالة المستخدم');
    }
  }

  void _showDeleteUserConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'تأكيد حذف المستخدم',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textSlate300,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                            text: 'هل أنت متأكد من حذف حساب\n'),
                        TextSpan(
                          text: '«${user['name'] ?? user['email']}»',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '؟'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيتم حذف بيانات المستخدم نهائياً',
                    style: TextStyle(
                      color: AppColors.textSlate500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.borderDark),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: AppColors.textSlate300,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await AuthService()
                                .deleteUserAccount(user['uid']);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSuccessSnackBar('تم حذف المستخدم بنجاح');
                            _loadUsers();
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            _showErrorSnackBar(
                                'حدث خطأ أثناء حذف المستخدم');
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
}
