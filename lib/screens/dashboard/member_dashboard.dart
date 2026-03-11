import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';

class MemberDashboard extends StatefulWidget {
  final String memberId;
  const MemberDashboard({super.key, required this.memberId});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  Member? _member;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;
  final _dbService = DatabaseService.instance;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    try {
      _member = await _dbService.getMember(widget.memberId);
      if (_member != null) {
        _transactions =
            await _dbService.getMemberTransactions(_member!.id!);
        _loans = await _dbService.getMemberLoans(_member!.id!);
      }
    } catch (e) {
      debugPrint('Load member error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _txColor(String type) {
    switch (type) {
      case 'savings': return Colors.blue;
      case 'loan_disbursement': return Colors.orange;
      case 'loan_repayment': return Colors.green;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMemberData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMemberData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile card
                    Card(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Text(
                                _member?.firstName[0].toUpperCase() ?? '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _member?.fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              'UMVA: ${_member?.umvaId ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              'Role: ${_member?.role.toUpperCase() ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Financial summary
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [
                        _buildCard('Savings',
                            Helpers.formatCurrency(_member?.savingsBalance ?? 0),
                            Icons.savings, Colors.blue),
                        _buildCard('Loans',
                            Helpers.formatCurrency(_member?.loanBalance ?? 0),
                            Icons.credit_card, Colors.orange),
                        _buildCard('Social Fund',
                            Helpers.formatCurrency(
                                _member?.socialFundBalance ?? 0),
                            Icons.volunteer_activism, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active loans
                    if (_loans.where((l) => l['status'] == 'active').isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Loans',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ..._loans
                                  .where((l) => l['status'] == 'active')
                                  .map((loan) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.orange.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            _loanRow('Loan Amount',
                                                Helpers.formatCurrency(
                                                    (loan['amount'] as num)
                                                        .toDouble())),
                                            _loanRow('Paid',
                                                Helpers.formatCurrency(
                                                    (loan['paidAmount'] as num?)
                                                            ?.toDouble() ??
                                                        0)),
                                            _loanRow(
                                              'Balance',
                                              Helpers.formatCurrency(
                                                  (loan['totalPayable'] as num)
                                                          .toDouble() -
                                                      ((loan['paidAmount']
                                                                  as num?)
                                                              ?.toDouble() ??
                                                          0)),
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      )),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Transactions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Transactions',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _transactions.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text('No transactions yet'),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _transactions.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final t = _transactions[i];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              _txColor(t['type'])
                                                  .withOpacity(0.15),
                                          child: Icon(_txIcon(t['type']),
                                              color: _txColor(t['type']),
                                              size: 20),
                                        ),
                                        title: Text(t['description'] ??
                                            t['type']),
                                        subtitle: Text(Helpers.formatDate(
                                            DateTime.parse(t['date']))),
                                        trailing: Text(
                                          Helpers.formatCurrency(
                                              (t['amount'] as num)
                                                  .toDouble()),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _txColor(t['type']),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _loanRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
