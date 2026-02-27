class LedgerTransaction {
  final String id;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String note;
  final DateTime date;
  final DateTime createdAt;

  LedgerTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.note = '',
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory LedgerTransaction.fromMap(String id, Map<String, dynamic> map) {
    return LedgerTransaction(
      id: id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'credit',
      note: map['note'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
