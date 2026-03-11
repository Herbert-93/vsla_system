import '../models/group.dart';
import '../models/member.dart';
import 'database_service.dart';

class MeetingService {
  static final MeetingService instance = MeetingService._internal();
  factory MeetingService() => _instance;
  static final MeetingService _instance = MeetingService._internal();
  MeetingService._internal();

  final DatabaseService _dbService = DatabaseService.instance;

  /// Calculates and returns meeting summary stats for a group.
  Future<Map<String, dynamic>> getMeetingSummary(String groupId) async {
    final transactions = await _dbService.getGroupTransactions(groupId);
    double totalSavings = 0;
    double totalLoans = 0;
    double totalRepayments = 0;
    double totalSocialFund = 0;
    double totalPenalties = 0;

    for (final t in transactions) {
      switch (t['type']) {
        case 'savings':
          totalSavings += (t['amount'] as num).toDouble();
          break;
        case 'loan_disbursement':
          totalLoans += (t['amount'] as num).toDouble();
          break;
        case 'loan_repayment':
          totalRepayments += (t['amount'] as num).toDouble();
          break;
        case 'social_fund_contribution':
          totalSocialFund += (t['amount'] as num).toDouble();
          break;
        case 'penalty':
          totalPenalties += (t['amount'] as num).toDouble();
          break;
      }
    }

    return {
      'totalSavings': totalSavings,
      'totalLoans': totalLoans,
      'totalRepayments': totalRepayments,
      'totalSocialFund': totalSocialFund,
      'totalPenalties': totalPenalties,
    };
  }

  /// Marks a meeting as completed and updates group meeting counter.
  Future<void> completeMeeting(
      Map<String, dynamic> meetingData, Group group) async {
    meetingData['status'] = 'completed';
    await _dbService.updateMeeting(meetingData);

    group.currentMeeting += 1;
    group.totalSavings += (meetingData['totalSavings'] as num?)?.toDouble() ?? 0;
    group.totalLoanOutstanding +=
        (meetingData['totalLoans'] as num?)?.toDouble() ?? 0;
    group.socialFundBalance +=
        (meetingData['totalSocialFund'] as num?)?.toDouble() ?? 0;

    await _dbService.updateGroup(group);
  }

  /// Calculates share-out amounts for all members.
  Map<String, double> calculateShareOut(
      List<Member> members, Group group, double additionalFunds) {
    final totalSavings =
        members.fold<double>(0, (s, m) => s + m.savingsBalance);
    if (totalSavings <= 0) return {};

    final totalPool = totalSavings + additionalFunds;
    final shares = <String, double>{};
    for (final m in members) {
      shares[m.id!] = (m.savingsBalance / totalSavings) * totalPool;
    }
    return shares;
  }
}
