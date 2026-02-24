import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';

class CategoriesGrosScreen extends StatefulWidget {
  const CategoriesGrosScreen({super.key});
  @override
  State<CategoriesGrosScreen> createState() => _CategoriesGrosScreenState();
}

class _CategoriesGrosScreenState extends State<CategoriesGrosScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  bool _hasSeeded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    var categories = await _categoryService.getCategories('gros');

    // If no categories exist, seed them first
    if (categories.isEmpty && !_hasSeeded) {
      _hasSeeded = true;
      await _categoryService.seedCategories();
      categories = await _categoryService.getCategories('gros');
    }

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _filteredCategories = categories;
      _isLoading = false;
    });
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((cat) => cat.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      'الفئات - بالجملة',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/shopping-type'),
                    icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: 24),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCategories,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'بحث عن فئات...',
                  hintStyle: const TextStyle(color: AppColors.textSlate400),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterCategories('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Categories Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredCategories.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(color: AppColors.textSlate400, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = _filteredCategories[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/products',
                                  arguments: {
                                    'shoppingType': 'gros',
                                    'categoryId': cat.id,
                                    'categoryName': cat.name,
                                  },
                                );
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: AppColors.surfaceDark,
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(
                                        cat.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (c, e, s) => Container(
                                          color: AppColors.surfaceDark,
                                          child: const Icon(Icons.image, color: AppColors.textSlate500, size: 28),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(color: AppColors.textSlate300, fontSize: 11, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(Icons.person_outline, 'حسابي', 3),
                _navItem(Icons.shopping_cart_outlined, 'السلة', 2, badge: 3),
                _navItem(Icons.category, 'الفئات', 1, isActive: true),
                _navItem(Icons.home_outlined, 'الرئيسية', 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, {bool isActive = false, int? badge}) {
    final color = isActive ? AppColors.primary : AppColors.textSlate400;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/shopping-type');
            break;
          case 1:
            // Already on categories
            break;
          case 2:
            // Cart — coming soon
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('السلة قريباً!', textAlign: TextAlign.center),
                backgroundColor: AppColors.surfaceDarkAlt,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 1),
              ),
            );
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (badge != null)
                Positioned(
                  top: -4, right: -6,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceDark, width: 1.5),
                    ),
                    child: Center(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
