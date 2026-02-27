import 'package:firebase_database/firebase_database.dart';
import '../models/ledger_transaction_model.dart';

class LedgerService {
  // Singleton
  static final LedgerService _instance = LedgerService._internal();
  factory LedgerService() => _instance;
  LedgerService._internal();

  DatabaseReference get _dbRef => FirebaseDatabase.instance.ref();

  /// Fetch all transactions for a specific user, sorted by date descending.
  Future<List<LedgerTransaction>> getTransactions(String userId) async {
    final snapshot = await _dbRef
        .child('ledger')
        .child(userId)
        .child('transactions')
        .get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final rawData = snapshot.value;
    if (rawData is! Map) return [];

    final List<LedgerTransaction> transactions = [];
    for (final entry in rawData.entries) {
      if (entry.value is Map) {
        final txMap = <String, dynamic>{};
        (entry.value as Map).forEach((key, value) {
          txMap[key.toString()] = value;
        });
        transactions.add(
          LedgerTransaction.fromMap(entry.key.toString(), txMap),
        );
      }
    }

    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Add a new transaction for a user.
  Future<void> addTransaction(String userId, LedgerTransaction tx) async {
    await _dbRef
        .child('ledger')
        .child(userId)
        .child('transactions')
        .push()
        .set(tx.toMap());
  }

  /// Delete a specific transaction.
  Future<void> deleteTransaction(String userId, String txId) async {
    await _dbRef
        .child('ledger')
        .child(userId)
        .child('transactions')
        .child(txId)
        .remove();
  }
}
