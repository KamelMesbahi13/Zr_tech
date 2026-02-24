import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
  String? _selectedWilaya;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  static const List<String> _wilayas = [
    '01 - أدرار', '02 - الشلف', '03 - الأغواط', '04 - أم البواقي',
    '05 - باتنة', '06 - بجاية', '07 - بسكرة', '08 - بشار',
    '09 - البليدة', '10 - البويرة', '11 - تمنراست', '12 - تبسة',
    '13 - تلمسان', '14 - تيارت', '15 - تيزي وزو', '16 - الجزائر',
    '17 - الجلفة', '18 - جيجل', '19 - سطيف', '20 - سعيدة',
    '21 - سكيكدة', '22 - سيدي بلعباس', '23 - عنابة', '24 - قالمة',
    '25 - قسنطينة', '26 - المدية', '27 - مستغانم', '28 - المسيلة',
    '29 - معسكر', '30 - ورقلة', '31 - وهران', '32 - البيض',
    '33 - إليزي', '34 - برج بوعريريج', '35 - بومرداس', '36 - الطارف',
    '37 - تندوف', '38 - تيسمسيلت', '39 - الوادي', '40 - خنشلة',
    '41 - سوق أهراس', '42 - تيبازة', '43 - ميلة', '44 - عين الدفلى',
    '45 - النعامة', '46 - عين تيموشنت', '47 - غرداية', '48 - غليزان',
    '49 - تيميمون', '50 - برج باجي مختار', '51 - أولاد جلال',
    '52 - بني عباس', '53 - عين صالح', '54 - عين قزام',
    '55 - تقرت', '56 - جانت', '57 - المغير', '58 - المنيعة',
    '59 - آفلو', '60 - بريكة', '61 - القنطرة', '62 - بئر العاتر',
    '63 - العريشة', '64 - قصر الشلالة', '65 - عين وسارة', '66 - مسعد',
    '67 - قصر البخاري', '68 - بوسعادة', '69 - الأبيض سيدي الشيخ',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_isLoading) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى الموافقة على الشروط والأحكام', textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().signUp(
      name: _nameController.text,
      storeName: _storeNameController.text,
      wilaya: _selectedWilaya ?? '',
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(
        context,
        '/login',
        arguments: result.message,
      );
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
    return Scaffold(
      body: Stack(
        children: [
          // Decorative top gradient line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.cyan.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Background blurs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
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
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 8),
                  // Title
                  const Text(
                    'ZR Technologie',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'وجهتك الأولى للإكسسوارات التقنية',
                    style: TextStyle(
                      color: AppColors.textSlate400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab Switcher with underline
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderDark, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: const Text(
                                'تسجيل الدخول',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSlate400,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 3,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ),
                            child: const Text(
                              'إنشاء حساب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Full Name
                  _buildLabel('الاسم الكامل'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'محمد علي',
                    icon: Icons.person_outline,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 20),

                  // Store Name
                  _buildLabel('اسم المتجر'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _storeNameController,
                    hint: 'اسم المحل أو الشركة',
                    icon: Icons.store_outlined,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 20),

                  // Wilaya
                  _buildLabel('الولاية'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                          child: Icon(Icons.location_on_outlined, color: AppColors.textSlate500, size: 20),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        'اختر الولاية',
                        style: TextStyle(color: AppColors.textSlate500, fontSize: 14),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      dropdownColor: AppColors.surfaceCard,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSlate400),
                      items: _wilayas.map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(w, textDirection: TextDirection.rtl),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedWilaya = val),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  _buildLabel('رقم الهاتف'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '05XXXXXXXX',
                    icon: Icons.smartphone,
                    keyboardType: TextInputType.phone,
                    fontFamily: 'Space Grotesk',
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _buildLabel('البريد الإلكتروني'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'example@domain.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    fontFamily: 'Space Grotesk',
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _buildLabel('كلمة المرور'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    textDirection: TextDirection.ltr,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Space Grotesk', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(fontFamily: 'Space Grotesk', color: AppColors.textSlate500),
                      prefixIcon: const Padding(
                        padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                        child: Icon(Icons.lock_outline, color: AppColors.textSlate500, size: 20),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSlate500,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreeTerms,
                          onChanged: (v) => setState(() => _agreeTerms = v!),
                          activeColor: AppColors.cyan,
                          side: const BorderSide(color: AppColors.textSlate500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.textSlate400,
                              fontSize: 14,
                              fontFamily: 'IBM Plex Sans Arabic',
                            ),
                            children: [
                              const TextSpan(text: 'أوافق على '),
                              TextSpan(
                                text: 'الشروط والأحكام',
                                style: TextStyle(color: AppColors.cyan),
                              ),
                              const TextSpan(text: ' و '),
                              TextSpan(
                                text: 'سياسة الخصوصية',
                                style: TextStyle(color: AppColors.cyan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'هل لديك حساب بالفعل؟ ',
                        style: TextStyle(color: AppColors.textSlate400, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSlate300,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.ltr,
    String? fontFamily,
  }) {
    return TextField(
      controller: controller,
      textDirection: textDirection,
      textAlign: textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: fontFamily ?? 'IBM Plex Sans Arabic',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: fontFamily ?? 'IBM Plex Sans Arabic',
          color: AppColors.textSlate500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(icon, color: AppColors.textSlate500, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }
}
