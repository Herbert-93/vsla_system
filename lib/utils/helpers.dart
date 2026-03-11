import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class Helpers {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'UGX ${formatter.format(amount)}';
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static double calculateLoanInterest(double principal, double rate) =>
      principal * (rate / 100);

  static double calculateTotalPayable(
          double principal, double interest) =>
      principal + interest;

  static String generateMeetingNumber(
          int cycleNumber, int meetingNumber) =>
      'C${cycleNumber.toString().padLeft(2, '0')}'
      'M${meetingNumber.toString().padLeft(2, '0')}';

  static bool isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  static bool isValidPhone(String phone) =>
      RegExp(r'^(?:256|0)[0-9]{9}$').hasMatch(phone);

  static String generateUmvaId(String firstName, String lastName) =>
      '${firstName.toLowerCase()}.${lastName.toLowerCase()}';

  static double calculateShareValue(int units, double shareValue) =>
      units * shareValue;

  static bool isLoanEligible(
          double loanAmount, double savingsBalance) =>
      loanAmount <= (savingsBalance * 3);

  static Map<String, dynamic> calculateMeetingStats(
      List<dynamic> transactions) {
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
      'netCashflow': totalSavings +
          totalRepayments +
          totalSocialFund +
          totalPenalties -
          totalLoans,
    };
  }

  static double parseAmount(String amount) {
    if (amount.isEmpty) return 0;
    return double.tryParse(amount.replaceAll(',', '')) ?? 0;
  }

  static String generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }
}
