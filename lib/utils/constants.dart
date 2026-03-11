class AppConstants {
  static const String appName = 'VSLA Desktop';
  static const String appVersion = '1.0.0';

  static const String databaseName = 'vsla.db';
  static const int databaseVersion = 2;

  static const String prefSelectedBank = 'selected_bank';
  static const String prefUserId = 'current_user_id';
  static const String prefUserName = 'current_user_name';
  static const String prefGroupId = 'group_id';

  static const double defaultShareValue = 1000;
  static const int defaultMinShareUnits = 1;
  static const int defaultMaxShareUnits = 5;
  static const double defaultMinSocialFund = 500;
  static const double defaultInterestRate = 30.0;
  static const int defaultMaxLoanMultiplier = 3;
  static const int defaultMinLoanPeriod = 4;
  static const int defaultMaxLoanPeriod = 12;

  static const String meetingStatusInProgress = 'in_progress';
  static const String meetingStatusCompleted = 'completed';
  static const String meetingStatusCancelled = 'cancelled';

  static const String transactionTypeSavings = 'savings';
  static const String transactionTypeLoanDisbursement = 'loan_disbursement';
  static const String transactionTypeLoanRepayment = 'loan_repayment';
  static const String transactionTypeSocialFundContribution =
      'social_fund_contribution';
  static const String transactionTypeSocialFundDistribution =
      'social_fund_distribution';
  static const String transactionTypePenalty = 'penalty';

  static const String rolePresident = 'president';
  static const String roleTreasurer = 'treasurer';
  static const String roleSecretary = 'secretary';
  static const String roleMember = 'member';

  static const String loanStatusActive = 'active';
  static const String loanStatusPaid = 'paid';
  static const String loanStatusDefaulted = 'defaulted';

  static const List<String> ugandaBanks = [
    'UGAFODE',
    'Centenary Bank',
    'Finance Trust Bank',
    'Pride Microfinance',
    'BRAC Uganda',
    'Post Bank Uganda',
    'Equity Bank',
    'Opportunity Bank',
  ];

  static const List<String> ugandaRegions = [
    'Central',
    'Eastern',
    'Northern',
    'Western',
  ];
}
