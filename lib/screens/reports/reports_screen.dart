import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  final String groupId;
  const ReportsScreen({super.key, required this.groupId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _dbService = DatabaseService.instance;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = true;
  String _selectedReport = 'summary';

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      _transactions =
          await _dbService.getGroupTransactions(widget.groupId);
      _meetings = await _dbService.getGroupMeetings(widget.groupId);
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedReport,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'summary', child: Text('Financial Summary')),
                      DropdownMenuItem(
                          value: 'transactions',
                          child: Text('All Transactions')),
                      DropdownMenuItem(
                          value: 'savings', child: Text('Savings Report')),
                      DropdownMenuItem(
                          value: 'loans', child: Text('Loans Report')),
                      DropdownMenuItem(
                          value: 'meetings',
                          child: Text('Meeting History')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedReport = v!),
                  ),
                ),
                Expanded(child: _buildReportContent()),
              ],
            ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReport) {
      case 'summary': return _buildSummaryReport();
      case 'transactions': return _buildTransactionsReport();
      case 'savings': return _buildSavingsReport();
      case 'loans': return _buildLoansReport();
      case 'meetings': return _buildMeetingsReport();
      default: return _buildSummaryReport();
    }
  }

  double _sumByType(String type) => _transactions
      .where((t) => t['type'] == type)
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  Widget _buildSummaryReport() {
    final totalSavings = _sumByType('savings');
    final totalLoans = _sumByType('loan_disbursement');
    final totalRepayments = _sumByType('loan_repayment');
    final totalSocialFund = _sumByType('social_fund_contribution');
    final totalPenalties = _sumByType('penalty');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Summary',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _sumItem('Total Savings', totalSavings, Icons.savings,
                    Colors.blue),
                _sumItem('Loans Disbursed', totalLoans,
                    Icons.credit_card, Colors.orange),
                _sumItem('Loan Repayments', totalRepayments,
                    Icons.payment, Colors.teal),
                _sumItem('Social Fund Collected', totalSocialFund,
                    Icons.volunteer_activism, Colors.green),
                _sumItem('Total Penalties', totalPenalties,
                    Icons.warning, Colors.red),
                const Divider(height: 24),
                _sumItem(
                  'Net Balance',
                  totalSavings +
                      totalRepayments +
                      totalSocialFund +
                      totalPenalties -
                      totalLoans,
                  Icons.account_balance,
                  Colors.purple,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meeting Statistics',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _statRow('Total Meetings', '${_meetings.length}'),
                _statRow('Total Transactions',
                    '${_transactions.length}'),
                _statRow('Avg Savings / Meeting',
                    Helpers.formatCurrency(_meetings.isEmpty
                        ? 0
                        : totalSavings / _meetings.length)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsReport() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, i) {
        final t = _transactions[i];
        final color = _txColor(t['type']);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(_txIcon(t['type']), color: color, size: 20),
            ),
            title: Text(t['description'] ?? t['type']),
            subtitle:
                Text(_dateFormat.format(DateTime.parse(t['date']))),
            trailing: Text(
              Helpers.formatCurrency((t['amount'] as num).toDouble()),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavingsReport() {
    final Map<String, double> memberSavings = {};
    for (final t in _transactions) {
      if (t['type'] == 'savings') {
        final id = t['memberId'] as String;
        memberSavings[id] =
            (memberSavings[id] ?? 0) + (t['amount'] as num).toDouble();
      }
    }
    if (memberSavings.isEmpty) {
      return const Center(child: Text('No savings recorded'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: memberSavings.entries.map((e) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Member: ${e.key.substring(0, 8)}...'),
            trailing: Text(
              Helpers.formatCurrency(e.value),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoansReport() {
    final loans = _transactions
        .where((t) => t['type'] == 'loan_disbursement')
        .toList();
    if (loans.isEmpty) {
      return const Center(child: Text('No loans recorded'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, i) {
        final loan = loans[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child:
                  Icon(Icons.credit_card, color: Colors.white),
            ),
            title: Text(
                'Loan to ${(loan['memberId'] as String).substring(0, 8)}...'),
            subtitle: Text(
                _dateFormat.format(DateTime.parse(loan['date']))),
            trailing: Text(
              Helpers.formatCurrency((loan['amount'] as num).toDouble()),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeetingsReport() {
    if (_meetings.isEmpty) {
      return const Center(child: Text('No meetings recorded'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meetings.length,
      itemBuilder: (context, i) {
        final m = _meetings[i];
        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text('${m['meetingNumber']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text('Meeting #${m['meetingNumber']}'),
            subtitle: Text(
                _dateFormat.format(DateTime.parse(m['date']))),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _statRow('Savings',
                        Helpers.formatCurrency((m['totalSavings'] as num?)?.toDouble() ?? 0)),
                    _statRow('Social Fund',
                        Helpers.formatCurrency((m['totalSocialFund'] as num?)?.toDouble() ?? 0)),
                    _statRow('Loans',
                        Helpers.formatCurrency((m['totalLoans'] as num?)?.toDouble() ?? 0)),
                    _statRow('Penalties',
                        Helpers.formatCurrency((m['totalPenalties'] as num?)?.toDouble() ?? 0)),
                    _statRow('Status', m['status'] ?? '-'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sumItem(String label, double amount, IconData icon, Color color,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: isTotal
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: isTotal ? 15 : 14)),
          ),
          Text(
            Helpers.formatCurrency(amount),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? color : null),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _txColor(String type) {
    switch (type) {
      case 'savings': return Colors.blue;
      case 'loan_disbursement': return Colors.orange;
      case 'loan_repayment': return Colors.teal;
      case 'social_fund_contribution': return Colors.purple;
      case 'penalty': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'savings': return Icons.savings;
      case 'loan_disbursement': return Icons.credit_card;
      case 'loan_repayment': return Icons.payment;
      case 'social_fund_contribution': return Icons.volunteer_activism;
      case 'penalty': return Icons.warning;
      default: return Icons.receipt;
    }
  }
}
