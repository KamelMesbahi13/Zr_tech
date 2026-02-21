import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _grosCategories = [];
  List<CategoryModel> _detailCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final gros = await _categoryService.getCategories('gros');
      final detail = await _categoryService.getCategories('detail');
      if (!mounted) return;
      setState(() {
        _grosCategories = gros;
        _detailCategories = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('حدث خطأ أثناء تحميل الفئات');
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

  String get _currentType => _tabController.index == 0 ? 'gros' : 'detail';

  List<CategoryModel> get _currentCategories =>
      _tabController.index == 0 ? _grosCategories : _detailCategories;

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
                              ? Colors.white
                              : AppColors.textSlate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'رفع صورة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !useUrl
                                ? Colors.white
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
                              useUrl ? Colors.white : AppColors.textSlate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'رابط URL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: useUrl
                                ? Colors.white
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
              color: Colors.white,
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
                        color: Colors.white,
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
                                    _loadCategories();
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
                        color: Colors.white,
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
                                    _loadCategories();
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
                        color: Colors.white,
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
                            color: Colors.white,
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
                            _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
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
              width: 250,
              height: 250,
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Logout button
                      _buildIconButton(
                        icon: Icons.logout,
                        color: Colors.red,
                        bgColor: Colors.red.withValues(alpha: 0.1),
                        onTap: _handleLogout,
                      ),
                      const Spacer(),
                      // Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'لوحة التحكم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'إدارة فئات المنتجات',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Admin avatar
                      Container(
                        width: 44,
                        height: 44,
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
                        child: const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),

                // ── TAB BAR ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSlate400,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'بالجملة'),
                        Tab(text: 'بالتجزئة'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── CATEGORY COUNT ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_currentCategories.length}',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'الفئات',
                        style: TextStyle(
                          color: AppColors.textSlate400,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CATEGORY LIST ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCategoryList(_grosCategories),
                            _buildCategoryList(_detailCategories),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ── FAB ──
      floatingActionButton: Container(
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
          onPressed: _showAddCategoryDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة فئة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
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
      onRefresh: _loadCategories,
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
          // Action buttons
          Column(
            children: [
              // Edit button
              _buildSmallButton(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: () => _showEditCategoryDialog(category),
              ),
              const SizedBox(height: 8),
              // Delete button
              _buildSmallButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () => _showDeleteConfirmation(category),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الترتيب: ${category.order}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.id,
                      style: const TextStyle(
                        color: AppColors.textSlate500,
                        fontSize: 11,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.surfaceCard,
              child: category.image.isNotEmpty
                  ? _buildImageWidget(
                      category.image,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.textSlate500,
                      size: 28,
                    ),
            ),
          ),
        ],
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
}
