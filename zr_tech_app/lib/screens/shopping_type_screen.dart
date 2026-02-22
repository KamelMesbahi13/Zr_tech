import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShoppingTypeScreen extends StatelessWidget {
  const ShoppingTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryDark.withValues(alpha: 0.2)))),
          Positioned(bottom: -50, right: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight.withValues(alpha: 0.1)))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text('ZR Technologie', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, color: AppColors.textSlate400, size: 24)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('اختر نوع التسوق', style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('يرجى تحديد طريقة الشراء للمتابعة لتخصيص تجربتك', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSlate400, fontSize: 14)),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _card('بالجملة', 'للشركات والتجار', Icons.inventory_2_outlined, () => Navigator.pushNamed(context, '/login')),
                      const SizedBox(height: 24),
                      _card('بالتجزئة', 'للاستخدام الشخصي', Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, '/categories', arguments: 'detail')),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: AppColors.borderGradient, boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.1), blurRadius: 20)]),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceInput),
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primaryLight.withValues(alpha: 0.2), AppColors.primaryDark.withValues(alpha: 0.2)]), border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3))),
              child: Icon(icon, color: AppColors.primaryLight, size: 28),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSlate400, fontSize: 14)),
            ]),
          ]),
        ),
      ),
    );
  }
}
