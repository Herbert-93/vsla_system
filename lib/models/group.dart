class Group {
  String? id;
  String name;
  String groupCode;
  String bankName;
  DateTime formationDate;
  String presidentId;
  String treasurerId;
  String secretaryId;
  int totalMembers;
  double totalSavings;
  double totalLoanOutstanding;
  double socialFundBalance;
  bool isActive;
  DateTime? cycleStartDate;
  int cycleDuration; // in weeks
  int currentMeeting;

  Group({
    this.id,
    required this.name,
    required this.groupCode,
    required this.bankName,
    required this.formationDate,
    required this.presidentId,
    required this.treasurerId,
    required this.secretaryId,
    this.totalMembers = 0,
    this.totalSavings = 0.0,
    this.totalLoanOutstanding = 0.0,
    this.socialFundBalance = 0.0,
    this.isActive = true,
    this.cycleStartDate,
    this.cycleDuration = 52,
    this.currentMeeting = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'groupCode': groupCode,
      'bankName': bankName,
      'formationDate': formationDate.toIso8601String(),
      'presidentId': presidentId,
      'treasurerId': treasurerId,
      'secretaryId': secretaryId,
      'totalMembers': totalMembers,
      'totalSavings': totalSavings,
      'totalLoanOutstanding': totalLoanOutstanding,
      'socialFundBalance': socialFundBalance,
      'isActive': isActive ? 1 : 0,
      'cycleStartDate': cycleStartDate?.toIso8601String(),
      'cycleDuration': cycleDuration,
      'currentMeeting': currentMeeting,
      'isSynced': 0,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      groupCode: map['groupCode'],
      bankName: map['bankName'],
      formationDate: DateTime.parse(map['formationDate']),
      presidentId: map['presidentId'] ?? '',
      treasurerId: map['treasurerId'] ?? '',
      secretaryId: map['secretaryId'] ?? '',
      totalMembers: map['totalMembers'] ?? 0,
      totalSavings: (map['totalSavings'] as num?)?.toDouble() ?? 0.0,
      totalLoanOutstanding:
          (map['totalLoanOutstanding'] as num?)?.toDouble() ?? 0.0,
      socialFundBalance:
          (map['socialFundBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] == 1,
      cycleStartDate: map['cycleStartDate'] != null
          ? DateTime.parse(map['cycleStartDate'])
          : null,
      cycleDuration: map['cycleDuration'] ?? 52,
      currentMeeting: map['currentMeeting'] ?? 0,
    );
  }
}
