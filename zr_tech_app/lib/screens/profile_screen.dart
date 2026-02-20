import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService().getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _user = userData;
      _isLoading = false;
    });
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                            ),
                            const Text(
                              'حسابي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 40), // balance
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryDark, AppColors.primaryLight],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _user?.name.isNotEmpty == true
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // User name
                        Text(
                          _user?.name ?? 'مستخدم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? '',
                          style: const TextStyle(
                            color: AppColors.textSlate400,
                            fontSize: 14,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Info cards
                        _infoCard(
                          icon: Icons.person_outline,
                          label: 'الاسم الكامل',
                          value: _user?.name ?? '—',
                        ),
                        const SizedBox(height: 12),
                        _infoCard(
                          icon: Icons.mail_outline,
                          label: 'البريد الإلكتروني',
                          value: _user?.email ?? '—',
                          isLTR: true,
                        ),
                        const SizedBox(height: 12),
                        _infoCard(
                          icon: Icons.smartphone,
                          label: 'رقم الهاتف',
                          value: _user?.phone ?? '—',
                          isLTR: true,
                        ),
                        const SizedBox(height: 36),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                              label: const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.08),
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
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
                _navItem(Icons.person, 'حسابي', 3, isActive: true),
                _navItem(Icons.shopping_cart_outlined, 'السلة', 2),
                _navItem(Icons.category_outlined, 'الفئات', 1),
                _navItem(Icons.home_outlined, 'الرئيسية', 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    bool isLTR = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSlate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: isLTR ? 'Space Grotesk' : null,
                  ),
                  textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index,
      {bool isActive = false}) {
    final color = isActive ? AppColors.primary : AppColors.textSlate400;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/shopping-type');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/categories');
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
            // Already on profile
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
