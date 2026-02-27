class UserModel {
  final String uid;
  final String name;
  final String storeName;
  final String wilaya;
  final String email;
  final String phone;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String role; // 'user' | 'admin'

  UserModel({
    required this.uid,
    required this.name,
    this.storeName = '',
    this.wilaya = '',
    required this.email,
    required this.phone,
    this.status = 'pending',
    this.role = 'user',
  });

  /// Convert to a Map for Realtime Database storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'storeName': storeName,
      'wilaya': wilaya,
      'email': email,
      'phone': phone,
      'status': status,
      'role': role,
    };
  }

  /// Create a UserModel from a Realtime Database document Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      storeName: map['storeName'] ?? '',
      wilaya: map['wilaya'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      status: map['status'] ?? 'pending',
      role: map['role'] ?? 'user',
    );
  }
}

