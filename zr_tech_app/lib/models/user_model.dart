class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
  });

  /// Convert to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  /// Create a UserModel from a Firestore document Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
