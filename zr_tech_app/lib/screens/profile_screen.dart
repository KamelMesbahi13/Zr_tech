import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../theme/responsive_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _userEmail = user.email;
    final userData = await authService.getCurrentUserData();

    if (!mounted) return;

    setState(() {
      if (userData != null) {
        _userData = {
          'name': userData.name,
          'storeName': userData.storeName,
          'wilaya': userData.wilaya,
          'phone': userData.phone,
          'status': userData.status,
        };
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: Responsive.sp(256),
              height: Responsive.sp(256),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: Responsive.sp(256),
              height: Responsive.sp(256),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(16)),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: Responsive.sp(40),
                                  height: Responsive.sp(40),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceDarkAlt,
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: Responsive.sp(20)),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'الملف الشخصي',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: Responsive.fp(22),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.sp(32)),

                            // Avatar
                            Container(
                              width: Responsive.sp(80),
                              height: Responsive.sp(80),
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
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.person, color: Colors.white, size: Responsive.sp(40)),
                            ),
                            SizedBox(height: Responsive.sp(16)),

                            // Name
                            Text(
                              _userData?['name'] ?? 'مستخدم',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: Responsive.fp(22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Responsive.sp(4)),
                            Text(
                              _userEmail ?? '',
                              style: TextStyle(
                                color: AppColors.textSlate400,
                                fontSize: Responsive.fp(14),
                                fontFamily: 'Space Grotesk',
                              ),
                            ),
                            SizedBox(height: Responsive.sp(32)),

                            // Info cards
                            _buildInfoCard(Icons.store_outlined, 'اسم المتجر', _userData?['storeName'] ?? '-'),
                            SizedBox(height: Responsive.sp(12)),
                            _buildInfoCard(Icons.location_on_outlined, 'الولاية', _userData?['wilaya'] ?? '-'),
                            SizedBox(height: Responsive.sp(12)),
                            _buildInfoCard(Icons.phone_outlined, 'رقم الهاتف', _userData?['phone'] ?? '-'),
                            SizedBox(height: Responsive.sp(12)),
                            _buildInfoCard(
                              _userData?['status'] == 'approved' ? Icons.check_circle_outline : Icons.access_time,
                              'حالة الحساب',
                              _userData?['status'] == 'approved' ? 'مفعّل' : _userData?['status'] == 'pending' ? 'قيد المراجعة' : (_userData?['status'] ?? '-'),
                              valueColor: _userData?['status'] == 'approved' ? Colors.green : Colors.orange,
                            ),
                            SizedBox(height: Responsive.sp(32)),

                            // Logout
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await AuthService().logout();
                                  if (!mounted) return;
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                icon: Icon(Icons.logout, color: Colors.red, size: Responsive.sp(20)),
                                label: Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: Responsive.fp(14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                  padding: EdgeInsets.symmetric(vertical: Responsive.sp(14)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: Responsive.sp(24)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(8)),
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

  Widget _buildInfoCard(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label, style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(12))),
                SizedBox(height: Responsive.sp(4)),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: Responsive.fp(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Responsive.sp(14)),
          Container(
            width: Responsive.sp(44),
            height: Responsive.sp(44),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: Responsive.sp(22)),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, {bool isActive = false}) {
    final color = isActive ? AppColors.primary : AppColors.textSlate400;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/shopping-type');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/categories-gros');
            break;
          case 2:
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
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Responsive.sp(24)),
          SizedBox(height: Responsive.sp(4)),
          Text(label, style: TextStyle(color: color, fontSize: Responsive.fp(10), fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
