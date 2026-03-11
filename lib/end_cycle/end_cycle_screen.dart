import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class EndCycleScreen extends StatefulWidget {
  final Group group;
  final List<Member> members;

  const EndCycleScreen({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<EndCycleScreen> createState() => _EndCycleScreenState();
}

class _EndCycleScreenState extends State<EndCycleScreen> {
  bool _isLoading = true;
  bool _canEndCycle = false;
  List<String> _errors = [];
  Map<String, dynamic> _shareOutDetails = {};
  final _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    setState(() {
      _isLoading = true;
      _errors = [];
    });

    try {
      final db = await _dbService.database;

      // Check pending uploads
      final pendingUploads = await db.query('meetings',
          where: 'groupId = ? AND isSynced = ?',
          whereArgs: [widget.group.id, 0]);
      if (pendingUploads.isNotEmpty) {
        _errors.add(
            '⚠️ ${pendingUploads.length} meeting(s) not uploaded to server');
      }

      // Check cycle duration
      if (widget.group.cycleStartDate != null) {
        final endDate = widget.group.cycleStartDate!
            .add(Duration(days: widget.group.cycleDuration * 7));
        if (DateTime.now().isBefore(endDate)) {
          _errors.add('⚠️ Cycle not yet completed');
        }
      }

      // Check outstanding loans
      final activeLoans = await db.query('loans',
          where: 'groupId = ? AND status = ?',
          whereArgs: [widget.group.id, 'active']);
      if (activeLoans.isNotEmpty) {
        _errors.add(
            '⚠️ ${activeLoans.length} outstanding loan(s) not cleared');
      }

      _calculateShareOut();

      setState(() {
        _canEndCycle = _errors.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateShareOut() {
    final totalSavings = widget.members
        .fold<double>(0, (s, m) => s + m.savingsBalance);
    final totalPool = totalSavings + widget.group.socialFundBalance;

    final shares = <String, double>{};
    if (totalSavings > 0) {
      for (final m in widget.members) {
        shares[m.id!] = (m.savingsBalance / totalSavings) * totalPool;
      }
    }

    _shareOutDetails = {
      'totalSavings': totalSavings,
      'totalSocialFund': widget.group.socialFundBalance,
      'totalPool': totalPool,
      'memberShares': shares,
    };
  }

  Future<void> _endCycle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Cycle'),
        content: const Text(
            'This will distribute all funds and reset the cycle. This action cannot be undone. Proceed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Cycle'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final shares =
          _shareOutDetails['memberShares'] as Map<String, double>;

      for (final entry in shares.entries) {
        await _dbService.insertTransaction({
          'id': const Uuid().v4(),
          'groupId': widget.group.id,
          'memberId': entry.key,
          'meetingId': '',
          'type': 'share_out',
          'amount': entry.value,
          'description': 'Cycle share-out',
          'date': DateTime.now().toIso8601String(),
        });
      }

      // Reset group for new cycle
      widget.group.cycleStartDate = DateTime.now();
      widget.group.currentMeeting = 0;
      widget.group.totalSavings = 0;
      widget.group.totalLoanOutstanding = 0;
      widget.group.socialFundBalance = 0;
      await _dbService.updateGroup(widget.group);

      // Reset member balances
      for (final m in widget.members) {
        m.savingsBalance = 0;
        m.loanBalance = 0;
        m.socialFundBalance = 0;
        await _dbService.updateMember(m);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle ended successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending cycle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('End Cycle'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Eligibility
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eligibility Check',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_errors.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All requirements met. You can end the cycle.',
                                      style: TextStyle(
                                          color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._errors.map((err) => Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.red.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(err,
                                              style: TextStyle(
                                                  color: Colors.red
                                                      .shade700))),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Share-out
                  if (_shareOutDetails.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Share-out Calculation',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _row('Total Savings',
                                Helpers.formatCurrency((_shareOutDetails['totalSavings'] as num).toDouble())),
                            _row('Social Fund',
                                Helpers.formatCurrency((_shareOutDetails['totalSocialFund'] as num).toDouble())),
                            const Divider(),
                            _row('Total Pool',
                                Helpers.formatCurrency((_shareOutDetails['totalPool'] as num).toDouble()),
                                bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Member Shares',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...(_shareOutDetails['memberShares']
                                    as Map<String, double>)
                                .entries
                                .map((entry) {
                              final m = widget.members.firstWhere(
                                  (m) => m.id == entry.key,
                                  orElse: () => widget.members.first);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(m.fullName),
                                    Text(
                                      Helpers.formatCurrency(entry.value),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _canEndCycle ? _endCycle : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('END CYCLE',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: bold ? Colors.blue : null)),
        ],
      ),
    );
  }
}
