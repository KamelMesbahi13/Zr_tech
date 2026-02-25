import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../theme/responsive_wrapper.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const String _adminEmail = 'admin@zrtech.com';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading) return;
    
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    
    // Hard check for admin email before even calling Firebase
    if (email != _adminEmail) {
      _showErrorSnackBar('غير مصرح لك بالدخول. هذه الصفحة مخصصة للإدارة فقط.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().login(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Double check in case of success
      if (email == _adminEmail) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        // Fallback in case they somehow log in with another email while bypassing the first check
        await AuthService().logout();
        _showErrorSnackBar('غير مصرح لك بالدخول.');
      }
    } else {
      _showErrorSnackBar(result.message);
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

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: Stack(
        children: [
          // Background blurs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: Responsive.sp(300),
              height: Responsive.sp(300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: Responsive.sp(300),
              height: Responsive.sp(300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(32)),
                child: ResponsiveWrapper(
                  maxWidth: 480,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: Responsive.sp(120),
                        height: Responsive.sp(120),
                      ),
                      SizedBox(height: Responsive.sp(16)),
                      // Title
                      Text(
                        'تسجيل دخول الإدارة',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: Responsive.fp(28),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Responsive.sp(4)),
                      Text(
                        'الرجاء إدخال بيانات الدخول الخاصة بالإدارة',
                        style: TextStyle(
                          color: AppColors.textSlate400,
                          fontSize: Responsive.fp(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: Responsive.sp(40)),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'admin@zrtech.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isLTR: true,
                      ),
                      SizedBox(height: Responsive.sp(20)),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isLTR: true,
                      ),

                      SizedBox(height: Responsive.sp(32)),

                      // Login Button (No Sign up tab needed)
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
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: Responsive.sp(24),
                                    height: Responsive.sp(24),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.admin_panel_settings, color: Colors.white, size: Responsive.sp(20)),
                                      SizedBox(width: Responsive.sp(8)),
                                      Text(
                                        'دخول الإدارة',
                                        style: TextStyle(
                                          fontSize: Responsive.fp(16),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(16)),
                      // Back to User Panel (Optional helpful link)
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text('العودة لتسجيل دخول المستخدمين', style: TextStyle(color: AppColors.primaryDark, fontSize: Responsive.fp(13))),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
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
            style: TextStyle(
              color: AppColors.textSlate300,
              fontSize: Responsive.fp(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: Responsive.sp(8)),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
          textAlign: isLTR ? TextAlign.left : TextAlign.right,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: isLTR ? 'Space Grotesk' : null,
            fontSize: Responsive.fp(14),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: isLTR ? 'Space Grotesk' : null,
              color: AppColors.textSlate500,
              fontSize: Responsive.fp(14),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
              child: Icon(icon, color: AppColors.textSlate400, size: Responsive.sp(22)),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSlate400,
                      size: Responsive.sp(20),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
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
}
