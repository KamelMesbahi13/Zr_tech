import 'package:firebase_database/firebase_database.dart';
import '../models/wilaya_model.dart';

class WilayaService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('settings').child('wilayas');

  /// Fetch only active wilayas (for customer order form dropdown).
  Future<List<WilayaModel>> getActiveWilayas() async {
    final snapshot = await _dbRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final wilayas = <WilayaModel>[];

    data.forEach((key, value) {
      final wilaya =
          WilayaModel.fromMap(key, Map<String, dynamic>.from(value as Map));
      if (wilaya.isActive) {
        wilayas.add(wilaya);
      }
    });

    wilayas.sort((a, b) => a.id.compareTo(b.id));
    return wilayas;
  }

  /// Fetch all wilayas (for admin management).
  Future<List<WilayaModel>> getAllWilayas() async {
    final snapshot = await _dbRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final wilayas = <WilayaModel>[];

    data.forEach((key, value) {
      wilayas.add(
        WilayaModel.fromMap(key, Map<String, dynamic>.from(value as Map)),
      );
    });

    wilayas.sort((a, b) => a.id.compareTo(b.id));
    return wilayas;
  }

  /// Add a new wilaya.
  Future<void> addWilaya({
    required String name,
    required double homeDeliveryPrice,
    required double deskDeliveryPrice,
  }) async {
    // Generate next wilaya ID
    final snapshot = await _dbRef.get();
    int maxNum = 0;
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final key in data.keys) {
        final num = int.tryParse(key) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    final nextId = (maxNum + 1).toString().padLeft(2, '0');

    await _dbRef.child(nextId).set({
      'name': name,
      'homeDeliveryPrice': homeDeliveryPrice,
      'deskDeliveryPrice': deskDeliveryPrice,
      'isActive': true,
    });
  }

  /// Update an existing wilaya.
  Future<void> updateWilaya({
    required String wilayaId,
    required String name,
    required double homeDeliveryPrice,
    required double deskDeliveryPrice,
  }) async {
    await _dbRef.child(wilayaId).update({
      'name': name,
      'homeDeliveryPrice': homeDeliveryPrice,
      'deskDeliveryPrice': deskDeliveryPrice,
    });
  }

  /// Delete a wilaya.
  Future<void> deleteWilaya(String wilayaId) async {
    await _dbRef.child(wilayaId).remove();
  }

  /// Toggle wilaya active status.
  Future<void> toggleWilaya(String wilayaId, bool isActive) async {
    await _dbRef.child(wilayaId).update({'isActive': isActive});
  }

  /// Seed the initial 58 wilayas of Algeria with default delivery prices.
  /// Only seeds if the collection is empty.
  Future<void> seedWilayas() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists && snapshot.value != null) return; // Already seeded

    const defaultHomePrice = 600.0;
    const defaultDeskPrice = 400.0;

    final wilayas = <String, Map<String, dynamic>>{
      '01': {'name': 'أدرار', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '02': {'name': 'الشلف', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '03': {'name': 'الأغواط', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '04': {'name': 'أم البواقي', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '05': {'name': 'باتنة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '06': {'name': 'بجاية', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '07': {'name': 'بسكرة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '08': {'name': 'بشار', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '09': {'name': 'البليدة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '10': {'name': 'البويرة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '11': {'name': 'تمنراست', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '12': {'name': 'تبسة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '13': {'name': 'تلمسان', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '14': {'name': 'تيارت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '15': {'name': 'تيزي وزو', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '16': {'name': 'الجزائر', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '17': {'name': 'الجلفة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '18': {'name': 'جيجل', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '19': {'name': 'سطيف', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '20': {'name': 'سعيدة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '21': {'name': 'سكيكدة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '22': {'name': 'سيدي بلعباس', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '23': {'name': 'عنابة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '24': {'name': 'قالمة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '25': {'name': 'قسنطينة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '26': {'name': 'المدية', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '27': {'name': 'مستغانم', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '28': {'name': 'المسيلة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '29': {'name': 'معسكر', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '30': {'name': 'ورقلة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '31': {'name': 'وهران', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '32': {'name': 'البيض', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '33': {'name': 'إليزي', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '34': {'name': 'برج بوعريريج', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '35': {'name': 'بومرداس', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '36': {'name': 'الطارف', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '37': {'name': 'تندوف', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '38': {'name': 'تيسمسيلت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '39': {'name': 'الوادي', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '40': {'name': 'خنشلة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '41': {'name': 'سوق أهراس', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '42': {'name': 'تيبازة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '43': {'name': 'ميلة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '44': {'name': 'عين الدفلى', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '45': {'name': 'النعامة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '46': {'name': 'عين تموشنت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '47': {'name': 'غرداية', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '48': {'name': 'غليزان', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '49': {'name': 'تيميمون', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '50': {'name': 'برج باجي مختار', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '51': {'name': 'أولاد جلال', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '52': {'name': 'بني عباس', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '53': {'name': 'عين صالح', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '54': {'name': 'عين قزام', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '55': {'name': 'توقرت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '56': {'name': 'جانت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '57': {'name': 'المغير', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '58': {'name': 'المنيعة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '59': {'name': 'بريان', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '60': {'name': 'أفلو', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '61': {'name': 'عين وسارة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '62': {'name': 'المقارين', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '63': {'name': 'بوسعادة', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '64': {'name': 'المرسى', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '65': {'name': 'حاسي مسعود', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '66': {'name': 'تقرت', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '67': {'name': 'الأوراس', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '68': {'name': 'عين الإبل', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
      '69': {'name': 'سيدي المهدي', 'homeDeliveryPrice': defaultHomePrice, 'deskDeliveryPrice': defaultDeskPrice, 'isActive': true},
    };

    await _dbRef.set(wilayas);
  }
}
