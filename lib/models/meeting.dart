class Meeting {
  String? id;
  String groupId;
  int meetingNumber;
  DateTime date;
  Map<String, bool> attendance;
  double totalSavings;
  double totalSocialFund;
  double totalLoans;
  double totalPenalties;
  String status;
  String notes;
  bool verifiedByPresident;
  bool verifiedByTreasurer;
  bool verifiedBySecretary;
  DateTime createdAt;

  Meeting({
    this.id,
    required this.groupId,
    required this.meetingNumber,
    required this.date,
    Map<String, bool>? attendance,
    this.totalSavings = 0.0,
    this.totalSocialFund = 0.0,
    this.totalLoans = 0.0,
    this.totalPenalties = 0.0,
    this.status = 'in_progress',
    this.notes = '',
    this.verifiedByPresident = false,
    this.verifiedByTreasurer = false,
    this.verifiedBySecretary = false,
    DateTime? createdAt,
  })  : attendance = attendance ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'meetingNumber': meetingNumber,
      'date': date.toIso8601String(),
      'totalSavings': totalSavings,
      'totalSocialFund': totalSocialFund,
      'totalLoans': totalLoans,
      'totalPenalties': totalPenalties,
      'status': status,
      'notes': notes,
      'verifiedByPresident': verifiedByPresident ? 1 : 0,
      'verifiedByTreasurer': verifiedByTreasurer ? 1 : 0,
      'verifiedBySecretary': verifiedBySecretary ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'],
      groupId: map['groupId'],
      meetingNumber: map['meetingNumber'] ?? 0,
      date: DateTime.parse(map['date']),
      totalSavings: (map['totalSavings'] as num?)?.toDouble() ?? 0.0,
      totalSocialFund: (map['totalSocialFund'] as num?)?.toDouble() ?? 0.0,
      totalLoans: (map['totalLoans'] as num?)?.toDouble() ?? 0.0,
      totalPenalties: (map['totalPenalties'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'in_progress',
      notes: map['notes'] ?? '',
      verifiedByPresident: map['verifiedByPresident'] == 1,
      verifiedByTreasurer: map['verifiedByTreasurer'] == 1,
      verifiedBySecretary: map['verifiedBySecretary'] == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
