import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';

class SiteUpdateComment {
  final String id;
  final String authorName;
  final String text;
  final int createdAt;

  SiteUpdateComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory SiteUpdateComment.fromMap(String id, Map<dynamic, dynamic> map) {
    return SiteUpdateComment(
      id: id,
      authorName: (map['authorName'] ?? 'زائر').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class SiteUpdateModel {
  final String id;
  final String title;
  final String image;
  final String date;
  final int createdAt;
  final int likesCount;
  final List<SiteUpdateComment> comments;

  SiteUpdateModel({
    required this.id,
    required this.title,
    required this.image,
    required this.date,
    required this.createdAt,
    required this.likesCount,
    required this.comments,
  });

  factory SiteUpdateModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final commentsList = <SiteUpdateComment>[];
    final rawComments = map['comments'];
    if (rawComments is Map) {
      rawComments.forEach((k, v) {
        if (v is Map) {
          commentsList.add(SiteUpdateComment.fromMap(k.toString(), v));
        }
      });
      commentsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return SiteUpdateModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      image: (map['image'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      comments: commentsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'date': date,
      'createdAt': createdAt,
      'likesCount': likesCount,
    };
  }
}

class SiteUpdatesService {
  static final SiteUpdatesService _instance = SiteUpdatesService._internal();
  factory SiteUpdatesService() => _instance;
  SiteUpdatesService._internal();

  DatabaseReference get _dbRef => FirebaseDatabase.instance.ref();

  // ─── CONTACT PHONE (LOGIN / SIGNUP) ─────────────────────────────

  Future<String> getContactPhone() async {
    try {
      final snap = await _dbRef.child('settings').child('contact').child('phone').get();
      if (snap.exists && snap.value != null) {
        return snap.value.toString().trim();
      }
    } catch (_) {}
    return '';
  }

  Stream<String> listenToContactPhone() {
    try {
      return _dbRef.child('settings').child('contact').child('phone').onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          return event.snapshot.value.toString().trim();
        }
        return '';
      });
    } catch (_) {
      return Stream.value('');
    }
  }

  Future<void> setContactPhone(String phone) async {
    await AuthService().requireAdmin();
    await _dbRef.child('settings').child('contact').update({
      'phone': phone.trim(),
      'updatedAt': ServerValue.timestamp,
    });
  }

  // ─── HOME SCREEN UPDATES / PROMOTIONAL FEED ─────────────────────

  DatabaseReference get _updatesRef => _dbRef.child('settings').child('site_updates');

  Future<List<SiteUpdateModel>> getUpdates() async {
    try {
      final snap = await _updatesRef.get();
      if (!snap.exists || snap.value == null) return [];
      return _parseUpdates(snap.value);
    } catch (_) {
      return [];
    }
  }

  Stream<List<SiteUpdateModel>> listenToUpdates() {
    try {
      return _updatesRef.onValue.map((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return [];
        return _parseUpdates(event.snapshot.value);
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  List<SiteUpdateModel> _parseUpdates(dynamic raw) {
    if (raw is! Map) return [];
    final list = <SiteUpdateModel>[];
    raw.forEach((key, value) {
      if (value is Map) {
        list.add(SiteUpdateModel.fromMap(key.toString(), value));
      }
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addUpdate({
    required String title,
    required String image,
    String? date,
    int initialLikes = 0,
  }) async {
    await AuthService().requireAdmin();
    final now = DateTime.now();
    final dateStr = (date != null && date.trim().isNotEmpty)
        ? date.trim()
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final ref = _updatesRef.push();
    await ref.set({
      'title': title.trim(),
      'image': image.trim(),
      'date': dateStr,
      'createdAt': now.millisecondsSinceEpoch,
      'likesCount': initialLikes,
    });
  }

  Future<void> deleteUpdate(String updateId) async {
    await AuthService().requireAdmin();
    await _updatesRef.child(updateId).remove();
  }

  Future<void> toggleLike(String updateId, bool increment) async {
    final likesRef = _updatesRef.child(updateId).child('likesCount');
    await likesRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      final next = increment ? current + 1 : (current > 0 ? current - 1 : 0);
      return Transaction.success(next);
    });
  }

  Future<void> addComment({
    required String updateId,
    required String authorName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final ref = _updatesRef.child(updateId).child('comments').push();
    await ref.set({
      'authorName': authorName.trim().isEmpty ? 'زائر' : authorName.trim(),
      'text': text.trim(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
