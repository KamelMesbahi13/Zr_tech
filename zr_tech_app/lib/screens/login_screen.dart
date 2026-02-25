import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../theme/responsive_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _adminEmail = 'admin@zrtech.com';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _successMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _successMessage = args;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await AuthService().login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final email = _emailController.text.trim().toLowerCase();
      
      // Block admin from logging in via the user panel
      if (email == _adminEmail) {
        await AuthService().logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى تسجيل الدخول من صفحة الإدارة المخصصة', textAlign: TextAlign.center),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      // Fetch user data and check approval status
      final userData = await AuthService().getCurrentUserData();
      if (!mounted) return;

      if (userData == null) {
        await AuthService().logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لم يتم العثور على بيانات المستخدم', textAlign: TextAlign.center),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      if (userData.status == 'pending') {
        await AuthService().logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حسابك قيد المراجعة. يرجى انتظار اتصال من فريقنا لتفعيل الحساب',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      if (userData.status == 'rejected') {
        await AuthService().logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم رفض حسابك. يرجى التواصل مع الدعم لمزيد من المعلومات',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Approved user — proceed normally
      Navigator.pushReplacementNamed(context, '/categories-gros');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: Responsive.sp(40),
                          height: Responsive.sp(40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceDarkAlt,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: Responsive.sp(20)),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(8)),
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: Responsive.sp(120),
                        height: Responsive.sp(120),
                      ),
                      SizedBox(height: Responsive.sp(16)),
                      // Title
                      Text(
                        'ZR Technologie',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: Responsive.fp(28),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Responsive.sp(4)),
                      Text(
                        'وجهتك الأولى لكل ما يخص التكنولوجيا',
                        style: TextStyle(
                          color: AppColors.textSlate400,
                          fontSize: Responsive.fp(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: Responsive.sp(32)),

                      // Success message
                      if (_successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.sp(12)),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _successMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.green, fontSize: Responsive.fp(14)),
                          ),
                        ),
                        SizedBox(height: Responsive.sp(16)),
                      ],

                      // Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: Responsive.sp(10)),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'تسجيل الدخول',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.fp(14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/signup');
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: Responsive.sp(10)),
                                  child: Text(
                                    'إنشاء حساب',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSlate400,
                                      fontSize: Responsive.fp(14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.sp(28)),

                      // Email Field
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'البريد الإلكتروني',
                          style: TextStyle(
                            color: AppColors.textSlate300,
                            fontSize: Responsive.fp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(8)),
                      TextField(
                        controller: _emailController,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Space Grotesk', fontSize: Responsive.fp(14)),
                        decoration: InputDecoration(
                          hintText: 'name@example.com',
                          hintStyle: TextStyle(fontFamily: 'Space Grotesk', fontSize: Responsive.fp(14)),
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                            child: Icon(Icons.mail_outline, color: AppColors.textSlate400, size: Responsive.sp(22)),
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
                      SizedBox(height: Responsive.sp(20)),

                      // Password Field
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'كلمة المرور',
                          style: TextStyle(
                            color: AppColors.textSlate300,
                            fontSize: Responsive.fp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(8)),
                      TextField(
                        controller: _passwordController,
                        textDirection: TextDirection.ltr,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Space Grotesk', fontSize: Responsive.fp(14)),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(fontFamily: 'Space Grotesk', fontSize: Responsive.fp(14)),
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                            child: Icon(Icons.lock_outline, color: AppColors.textSlate400, size: Responsive.sp(22)),
                          ),
                          suffixIcon: IconButton(
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
                      SizedBox(height: Responsive.sp(4)),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'هل نسيت كلمة المرور؟',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: Responsive.fp(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(16)),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: Responsive.sp(16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'دخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.fp(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(32)),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.borderDark)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.sp(12)),
                            child: Text(
                              'أو تابع باستخدام',
                              style: TextStyle(color: AppColors.textSlate500, fontSize: Responsive.fp(14)),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.borderDark)),
                        ],
                      ),
                      SizedBox(height: Responsive.sp(24)),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _socialButton('Google', Icons.g_mobiledata),
                          ),
                          SizedBox(width: Responsive.sp(16)),
                          Expanded(
                            child: _socialButton('Apple', Icons.apple),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.sp(32)),

                      // Create Account Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟ ',
                            style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/signup');
                            },
                            child: Text(
                              'أنشئ حساباً جديداً',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: Responsive.fp(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _socialButton(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
        color: AppColors.surfaceDarkAlt,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Responsive.sp(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.textPrimary, size: Responsive.sp(22)),
                SizedBox(width: Responsive.sp(10)),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSlate300,
                    fontSize: Responsive.fp(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
