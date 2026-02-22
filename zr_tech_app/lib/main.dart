import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/shopping_type_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/products_screen.dart';
import 'screens/product_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAskK06JGcVlMO3en4O_dzdSzX9Q8_f16A",
        authDomain: "zr-tech.firebaseapp.com",
        projectId: "zr-tech",
        storageBucket: "zr-tech.firebasestorage.app",
        messagingSenderId: "712586347978",
        appId: "1:712586347978:web:20f1c2b7884d8eda92fb33",
        measurementId: "G-889L8GM7KC",
        databaseURL: "https://zr-tech-default-rtdb.europe-west1.firebasedatabase.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ZRTechApp());
}

class ZRTechApp extends StatelessWidget {
  const ZRTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZR Technologie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: child!,
          ),
        );
      },
      initialRoute: '/shopping-type',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/shopping-type': (context) => const ShoppingTypeScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/products': (context) => const ProductsScreen(),
        '/product-detail': (context) => const ProductDetailScreen(),
      },
    );
  }
}
