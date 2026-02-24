import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference get _dbRef => FirebaseDatabase.instance.ref();

  /// Stream of auth state changes (null = signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Fetch the UserModel from Realtime Database for the current user.
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _dbRef.child('users').child(user.uid).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromMap(data);
    }
    return null;
  }

  /// Register a new user with Firebase Auth and save profile to Realtime Database.
  Future<AuthResult> signUp({
    required String name,
    required String storeName,
    required String wilaya,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Client-side validation
    if (name.trim().isEmpty) {
      return AuthResult(success: false, message: 'الرجاء إدخال الاسم الكامل');
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      return AuthResult(
          success: false, message: 'الرجاء إدخال بريد إلكتروني صحيح');
    }
    if (phone.trim().isEmpty) {
      return AuthResult(success: false, message: 'الرجاء إدخال رقم الهاتف');
    }
    if (password.length < 6) {
      return AuthResult(
          success: false,
          message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }

    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Save additional user data to Realtime Database
      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        storeName: storeName.trim(),
        wilaya: wilaya.trim(),
        email: email.trim(),
        phone: phone.trim(),
      );

      await _dbRef
          .child('users')
          .child(credential.user!.uid)
          .set(userModel.toMap());

      // Sign out after registration so user goes to login screen
      await _auth.signOut();

      return AuthResult(success: true, message: 'تم إنشاء الحساب بنجاح');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapErrorToArabic(e.code));
    } catch (e) {
      return AuthResult(
          success: false, message: 'حدث خطأ غير متوقع. حاول مرة أخرى.');
    }
  }

  /// Sign in an existing user with email and password.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      return AuthResult(
          success: false, message: 'الرجاء إدخال بريد إلكتروني صحيح');
    }
    if (password.isEmpty) {
      return AuthResult(success: false, message: 'الرجاء إدخال كلمة المرور');
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(success: true, message: 'تم تسجيل الدخول بنجاح');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapErrorToArabic(e.code));
    } catch (e) {
      return AuthResult(
          success: false, message: 'حدث خطأ غير متوقع. حاول مرة أخرى.');
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Map Firebase Auth error codes to user-friendly Arabic messages.
  String _mapErrorToArabic(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب معطل. تواصل مع الدعم.';
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد الإلكتروني غير مفعّل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً. حاول لاحقاً.';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      default:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }
}
