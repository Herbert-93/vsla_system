class Member {
  String? id;
  String umvaId;
  String firstName;
  String lastName;
  String gender;
  String phone;
  String address;
  String region;
  String district;
  String constituency;
  String subCounty;
  String groupId;
  String role;
  double savingsBalance;
  double loanBalance;
  double socialFundBalance;
  bool isActive;
  DateTime registrationDate;

  Member({
    this.id,
    required this.umvaId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.phone,
    required this.address,
    required this.region,
    required this.district,
    required this.constituency,
    required this.subCounty,
    required this.groupId,
    this.role = 'member',
    this.savingsBalance = 0.0,
    this.loanBalance = 0.0,
    this.socialFundBalance = 0.0,
    this.isActive = true,
    required this.registrationDate,
  });

  String get fullName => '$firstName $lastName';
  String get username => '$firstName.$lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'umvaId': umvaId,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'phone': phone,
      'address': address,
      'region': region,
      'district': district,
      'constituency': constituency,
      'subCounty': subCounty,
      'groupId': groupId,
      'role': role,
      'savingsBalance': savingsBalance,
      'loanBalance': loanBalance,
      'socialFundBalance': socialFundBalance,
      'isActive': isActive ? 1 : 0,
      'registrationDate': registrationDate.toIso8601String(),
      'isSynced': 0,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      umvaId: map['umvaId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      gender: map['gender'],
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      region: map['region'] ?? '',
      district: map['district'] ?? '',
      constituency: map['constituency'] ?? '',
      subCounty: map['subCounty'] ?? '',
      groupId: map['groupId'],
      role: map['role'] ?? 'member',
      savingsBalance: (map['savingsBalance'] as num?)?.toDouble() ?? 0.0,
      loanBalance: (map['loanBalance'] as num?)?.toDouble() ?? 0.0,
      socialFundBalance:
          (map['socialFundBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] == 1,
      registrationDate: DateTime.parse(map['registrationDate']),
    );
  }
}
