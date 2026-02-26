class WilayaModel {
  final String id;
  final String name;
  final double homeDeliveryPrice;
  final double deskDeliveryPrice;
  final bool isActive;

  WilayaModel({
    required this.id,
    required this.name,
    required this.homeDeliveryPrice,
    required this.deskDeliveryPrice,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'homeDeliveryPrice': homeDeliveryPrice,
      'deskDeliveryPrice': deskDeliveryPrice,
      'isActive': isActive,
    };
  }

  factory WilayaModel.fromMap(String id, Map<String, dynamic> map) {
    return WilayaModel(
      id: id,
      name: map['name'] ?? '',
      homeDeliveryPrice: (map['homeDeliveryPrice'] ?? 0).toDouble(),
      deskDeliveryPrice: (map['deskDeliveryPrice'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}
