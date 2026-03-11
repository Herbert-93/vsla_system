class GroupSettings {
  String? id;
  String groupId;
  double shareValue;
  int minShareUnits;
  int maxShareUnits;
  double minSocialFundAmount;
  bool solidarityFundCompulsory;
  double interestRate;
  int maxLoanMultiplier;
  int minLoanPeriod;
  int maxLoanPeriod;
  bool enablePenalties;
  DateTime updatedAt;

  GroupSettings({
    this.id,
    required this.groupId,
    required this.shareValue,
    this.minShareUnits = 1,
    this.maxShareUnits = 5,
    required this.minSocialFundAmount,
    this.solidarityFundCompulsory = true,
    this.interestRate = 30.0,
    this.maxLoanMultiplier = 3,
    this.minLoanPeriod = 4,
    this.maxLoanPeriod = 12,
    this.enablePenalties = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'shareValue': shareValue,
      'minShareUnits': minShareUnits,
      'maxShareUnits': maxShareUnits,
      'minSocialFundAmount': minSocialFundAmount,
      'solidarityFundCompulsory': solidarityFundCompulsory ? 1 : 0,
      'interestRate': interestRate,
      'maxLoanMultiplier': maxLoanMultiplier,
      'minLoanPeriod': minLoanPeriod,
      'maxLoanPeriod': maxLoanPeriod,
      'enablePenalties': enablePenalties ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GroupSettings.fromMap(Map<String, dynamic> map) {
    return GroupSettings(
      id: map['id'],
      groupId: map['groupId'],
      shareValue: (map['shareValue'] as num?)?.toDouble() ?? 0.0,
      minShareUnits: map['minShareUnits'] ?? 1,
      maxShareUnits: map['maxShareUnits'] ?? 5,
      minSocialFundAmount:
          (map['minSocialFundAmount'] as num?)?.toDouble() ?? 0.0,
      solidarityFundCompulsory: map['solidarityFundCompulsory'] == 1,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 30.0,
      maxLoanMultiplier: map['maxLoanMultiplier'] ?? 3,
      minLoanPeriod: map['minLoanPeriod'] ?? 4,
      maxLoanPeriod: map['maxLoanPeriod'] ?? 12,
      enablePenalties: map['enablePenalties'] == 1,
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
