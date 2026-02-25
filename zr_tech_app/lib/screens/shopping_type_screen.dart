import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';

class ShoppingTypeScreen extends StatelessWidget {
  const ShoppingTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPad = Responsive.horizontalPadding;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: Container(width: Responsive.sp(300), height: Responsive.sp(300), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryDark.withValues(alpha: 0.2)))),
          Positioned(bottom: -50, right: -50, child: Container(width: Responsive.sp(400), height: Responsive.sp(400), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight.withValues(alpha: 0.1)))),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: Responsive.sp(16)),
                child: ResponsiveWrapper(
                  maxWidth: 500,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: Responsive.sp(40)),
                          Text('ZR Technologie', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(16), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                          IconButton(onPressed: () {}, icon: Icon(Icons.help_outline, color: AppColors.textSlate400, size: Responsive.sp(24))),
                        ],
                      ),
                      SizedBox(height: Responsive.sp(32)),
                      Text('اختر نوع التسوق', style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(30), fontWeight: FontWeight.bold)),
                      SizedBox(height: Responsive.sp(12)),
                      Text('يرجى تحديد طريقة الشراء للمتابعة لتخصيص تجربتك', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14))),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            // ── Decorative Graphic to fill vertical space ──
                            Container(
                              width: Responsive.sp(140),
                              height: Responsive.sp(140),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.cyan.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.store_mall_directory_rounded,
                                  size: Responsive.sp(64),
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            SizedBox(height: Responsive.sp(48)),

                            // ── Choices ──
                            _card(context, 'بالجملة', 'للشركات والتجار', Icons.inventory_2_outlined, () => Navigator.pushNamed(context, '/login')),
                            SizedBox(height: Responsive.sp(24)),
                            _card(context, 'بالتجزئة', 'للاستخدام الشخصي', Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, '/categories-detail')),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.sp(16)),
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

  Widget _card(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: AppColors.borderGradient, boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.1), blurRadius: 20)]),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceInput),
          padding: EdgeInsets.all(Responsive.sp(24)),
          child: Row(children: [
            Container(
              width: Responsive.sp(56), height: Responsive.sp(56),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primaryLight.withValues(alpha: 0.2), AppColors.primaryDark.withValues(alpha: 0.2)]), border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3))),
              child: Icon(icon, color: AppColors.primaryLight, size: Responsive.sp(28)),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.fp(20), fontWeight: FontWeight.bold)),
              SizedBox(height: Responsive.sp(4)),
              Text(subtitle, style: TextStyle(color: AppColors.textSlate400, fontSize: Responsive.fp(14))),
            ]),
          ]),
        ),
      ),
    );
  }
}
