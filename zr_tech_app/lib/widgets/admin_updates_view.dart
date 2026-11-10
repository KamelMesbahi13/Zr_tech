import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/site_updates_service.dart';

class AdminUpdatesView extends StatefulWidget {
  const AdminUpdatesView({super.key});

  @override
  State<AdminUpdatesView> createState() => _AdminUpdatesViewState();
}

class _AdminUpdatesViewState extends State<AdminUpdatesView> {
  final SiteUpdatesService _service = SiteUpdatesService();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _uploadedBase64Image = '';
  String _pickedFileName = '';
  bool _isSavingPhone = false;
  bool _isPublishingUpdate = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadCurrentPhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _titleController.dispose();
    _dateController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPhone() async {
    final phone = await _service.getContactPhone();
    if (!mounted) return;
    setState(() {
      _phoneController.text = phone;
    });
  }

  Future<void> _savePhone() async {
    if (_isSavingPhone) return;
    setState(() => _isSavingPhone = true);
    try {
      await _service.setContactPhone(_phoneController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم حفظ رقم الهاتف بنجاح وسيظهر في صفحة الدخول والتسجيل',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ أثناء حفظ رقم الهاتف', textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingPhone = false);
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final ext = (file.extension ?? 'jpeg').toLowerCase();
          final mime = ext == 'png'
              ? 'image/png'
              : ext == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg';
          final b64 = base64Encode(file.bytes!);
          setState(() {
            _uploadedBase64Image = 'data:$mime;base64,$b64';
            _pickedFileName = file.name;
            _imageUrlController.clear();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _publishUpdate() async {
    if (_isPublishingUpdate) return;
    final title = _titleController.text.trim();
    final image = _uploadedBase64Image.isNotEmpty
        ? _uploadedBase64Image
        : _imageUrlController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال عنوان الإعلان / المستجد', textAlign: TextAlign.center),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء رفع صورة من الجهاز أو إدخال رابط الصورة', textAlign: TextAlign.center),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPublishingUpdate = true);
    try {
      await _service.addUpdate(
        title: title,
        image: image,
        date: _dateController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _titleController.clear();
        _imageUrlController.clear();
        _uploadedBase64Image = '';
        _pickedFileName = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نشر الإعلان في الصفحة الرئيسية بنجاح!', textAlign: TextAlign.center),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ أثناء نشر الإعلان', textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishingUpdate = false);
    }
  }

  Widget _buildPreviewImage(String img) {
    if (img.startsWith('data:image')) {
      try {
        final bytes = base64Decode(img.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
      } catch (_) {}
    }
    return Image.network(
      img,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => Container(
        height: 140,
        color: AppColors.surfaceDarkAlt,
        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSlate400)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final previewImg = _uploadedBase64Image.isNotEmpty
        ? _uploadedBase64Image
        : _imageUrlController.text.trim();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding,
        vertical: Responsive.sp(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═════════════════════════════════════════════════════════════
          // SECTION 1: LOGIN & SIGNUP CONTACT PHONE NUMBER
          // ═════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رقم الهاتف في صفحة الدخول والتسجيل',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'يظهر هذا الرقم للتجار والزبائن في صفحتي تسجيل الدخول وإنشاء الحساب للتواصل وتفعيل الحسابات',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Space Grotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '0550 12 34 56',
                    hintStyle: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      color: AppColors.textSlate400,
                    ),
                    prefixIcon: const Icon(Icons.call_outlined, color: AppColors.primary),
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
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingPhone ? null : _savePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _isSavingPhone
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    label: const Text(
                      'حفظ رقم الهاتف',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ═════════════════════════════════════════════════════════════
          // SECTION 2: UPLOAD NEW HOME SCREEN UPDATE / PROMO IMAGE
          // ═════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006837).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF006837), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة إعلان / صورة في الصفحة الرئيسية',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ارفع صور العروض الجديدة أو الإعلانات لتظهر للزبائن في الصفحة الرئيسية مع الإعجابات والتعليقات',
                            style: TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title input
                const Text(
                  'عنوان الإعلان (يظهر في الشريط العلوي)',
                  style: TextStyle(color: AppColors.textSlate300, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'مثال: Mise à jour / Nouvel arrivage / إعلان هام',
                    hintStyle: const TextStyle(color: AppColors.textSlate400, fontSize: 13),
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.textSlate400),
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
                  ),
                ),
                const SizedBox(height: 14),

                // Date input
                const Text(
                  'تاريخ الإعلان',
                  style: TextStyle(color: AppColors.textSlate300, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _dateController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: '2026-11-10',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSlate400, size: 19),
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
                  ),
                ),
                const SizedBox(height: 14),

                // Image Picker button
                const Text(
                  'صورة الإعلان',
                  style: TextStyle(color: AppColors.textSlate300, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickBannerImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _pickedFileName.isNotEmpty
                                ? 'تم اختيار: $_pickedFileName'
                                : 'اختر صورة من الجهاز (JPG / PNG)',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Or Image URL
                TextField(
                  controller: _imageUrlController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  onChanged: (v) {
                    if (v.isNotEmpty) {
                      setState(() {
                        _uploadedBase64Image = '';
                        _pickedFileName = '';
                      });
                    } else {
                      setState(() {});
                    }
                  },
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أو الصق رابط الصورة المباشر (https://...)',
                    hintStyle: const TextStyle(color: AppColors.textSlate400, fontSize: 12),
                    prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textSlate400),
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
                  ),
                ),

                // Live Preview
                if (previewImg.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'معاينة الإعلان قبل النشر:',
                    style: TextStyle(color: AppColors.textSlate400, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF006837), Color(0xFF058247)],
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _dateController.text.trim(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Space Grotesk',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _titleController.text.trim().isEmpty
                                      ? 'عنوان الإعلان'
                                      : _titleController.text.trim(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 55),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: _buildPreviewImage(previewImg),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishingUpdate ? null : _publishUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006837),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _isPublishingUpdate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.publish_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'نشر الإعلان في الصفحة الرئيسية',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ═════════════════════════════════════════════════════════════
          // SECTION 3: PUBLISHED UPDATES LIST
          // ═════════════════════════════════════════════════════════════
          const Text(
            'الإعلانات والمستجدات المنشورة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SiteUpdateModel>>(
            stream: _service.listenToUpdates(),
            builder: (context, snapshot) {
              final updates = snapshot.data ?? [];
              if (updates.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: const Center(
                    child: Text(
                      'لا توجد إعلانات منشورة حالياً',
                      style: TextStyle(color: AppColors.textSlate400, fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: updates.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF006837), Color(0xFF058247)],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _service.deleteUpdate(item.id),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                tooltip: 'حذف الإعلان',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                item.date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontFamily: 'Space Grotesk',
                                ),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: _buildPreviewImage(item.image),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${item.likesCount} إعجاب',
                                style: const TextStyle(color: AppColors.textSlate300, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.mode_comment_outlined, color: AppColors.primary, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${item.comments.length} تعليق',
                                style: const TextStyle(color: AppColors.textSlate300, fontSize: 13),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _service.deleteUpdate(item.id),
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                label: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

