import 'package:firebase_database/firebase_database.dart';

class UserNote {
  final String id;
  final String text;
  final int createdAt;

  UserNote({required this.id, required this.text, required this.createdAt});

  factory UserNote.fromMap(String id, dynamic data) {
    if (data is Map) {
      return UserNote(
        id: id,
        text: (data['text'] ?? '').toString(),
        createdAt: (data['createdAt'] as int?) ?? 0,
      );
    }
    // Legacy: single string note
    return UserNote(id: id, text: data.toString(), createdAt: 0);
  }
}

class UserNoteService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Add a new note for a product.
  Future<void> addNote({
    required String userId,
    required String productId,
    required String noteText,
  }) async {
    final ref = _dbRef.child('user_notes').child(userId).child(productId).push();
    await ref.set({
      'text': noteText,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Delete a specific note by its ID.
  Future<void> deleteNote({
    required String userId,
    required String productId,
    required String noteId,
  }) async {
    await _dbRef
        .child('user_notes')
        .child(userId)
        .child(productId)
        .child(noteId)
        .remove();
  }

  /// Delete all notes for a product.
  Future<void> deleteAllNotes({
    required String userId,
    required String productId,
  }) async {
    await _dbRef
        .child('user_notes')
        .child(userId)
        .child(productId)
        .remove();
  }

  /// Get all notes for a specific product.
  Future<List<UserNote>> getProductNotes(String userId, String productId) async {
    final snapshot = await _dbRef
        .child('user_notes')
        .child(userId)
        .child(productId)
        .get();
    if (!snapshot.exists || snapshot.value == null) return [];
    return _parseNotes(snapshot.value);
  }

  /// Stream of notes for a specific product.
  Stream<List<UserNote>> listenToProductNotes(String userId, String productId) {
    return _dbRef
        .child('user_notes')
        .child(userId)
        .child(productId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      return _parseNotes(event.snapshot.value);
    });
  }

  /// Get a map of productId → note count for all products.
  Future<Map<String, int>> getUserNoteCounts(String userId) async {
    final snapshot = await _dbRef.child('user_notes').child(userId).get();
    if (!snapshot.exists || snapshot.value == null) return {};
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.map((productId, value) {
      if (value is Map) {
        return MapEntry(productId, value.length);
      }
      return MapEntry(productId, 1); // legacy single note
    });
  }

  /// Listen to note counts for all products.
  Stream<Map<String, int>> listenToUserNoteCounts(String userId) {
    return _dbRef.child('user_notes').child(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.map((productId, value) {
        if (value is Map) {
          return MapEntry(productId, value.length);
        }
        return MapEntry(productId, 1);
      });
    });
  }

  List<UserNote> _parseNotes(dynamic value) {
    if (value is String) {
      // Legacy single string note
      return [UserNote(id: '_legacy', text: value, createdAt: 0)];
    }
    if (value is Map) {
      final notes = <UserNote>[];
      final data = Map<String, dynamic>.from(value);
      data.forEach((key, val) {
        notes.add(UserNote.fromMap(key, val));
      });
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    }
    return [];
  }
}
