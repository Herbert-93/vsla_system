class Transaction {
  String? id;
  String groupId;
  String memberId;
  String meetingId;
  String type;
  double amount;
  String? description;
  DateTime date;

  Transaction({
    this.id,
    required this.groupId,
    required this.memberId,
    required this.meetingId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'memberId': memberId,
      'meetingId': meetingId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      groupId: map['groupId'],
      memberId: map['memberId'],
      meetingId: map['meetingId'] ?? '',
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }
}
