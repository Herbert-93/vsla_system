import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';

class LoanRequestScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;
  final String groupId;

  const LoanRequestScreen({
    super.key,
    required this.members,
    required this.meetingData,
    required this.groupId,
  });

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  Member? _selectedMember;
  final _amountController = TextEditingController();
  final _periodController = TextEditingController();
  double _interestRate = 30.0; // Should come from settings
  double _interestAmount = 0;
  double _totalPayable = 0;
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService.instance;

  List<String> loanPeriods = [
    '4 weeks',
    '8 weeks',
    '12 weeks',
    '16 weeks',
    '24 weeks'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Member Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Member>(
                    value: _selectedMember,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose member',
                    ),
                    items: widget.members.map((member) {
                      return DropdownMenuItem(
                        value: member,
                        child: Text(member.fullName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMember = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Loan Details
          if (_selectedMember != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loan Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Member info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Available Savings:'),
                              Text(
                                'UGX ${_selectedMember!.savingsBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Maximum Loan (3x savings):'),
                              Text(
                                'UGX ${(_selectedMember!.savingsBalance * 3).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loan amount
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount',
                        border: OutlineInputBorder(),
                        prefixText: 'UGX ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _calculateInterest();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Loan period
                    DropdownButtonFormField<String>(
                      value: _periodController.text.isEmpty
                          ? null
                          : _periodController.text,
                      decoration: const InputDecoration(
                        labelText: 'Loan Period',
                        border: OutlineInputBorder(),
                      ),
                      items: loanPeriods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _periodController.text = value!;
                          _calculateInterest();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Interest calculation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Interest Rate:'),
                              Text('$_interestRate%'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Interest Amount:'),
                              Text(
                                'UGX $_interestAmount',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Payable:'),
                              Text(
                                'UGX $_totalPayable',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: _submitLoanRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Submit Loan Request'),
            ),
          ],
        ],
      ),
    );
  }

  void _calculateInterest() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    _interestAmount = amount * (_interestRate / 100);
    _totalPayable = amount + _interestAmount;
    setState(() {});
  }

  Future<void> _submitLoanRequest() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Check if amount exceeds 3x savings
    if (amount > _selectedMember!.savingsBalance * 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan amount cannot exceed 3 times savings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create loan record
    String loanId = _uuid.v4();
    DateTime now = DateTime.now();
    DateTime dueDate = now.add(
        Duration(days: int.parse(_periodController.text.split(' ')[0]) * 7));

    Map<String, dynamic> loan = {
      'id': loanId,
      'memberId': _selectedMember!.id,
      'groupId': widget.groupId,
      'meetingId': widget.meetingData['id'],
      'amount': amount,
      'interestRate': _interestRate,
      'totalPayable': _totalPayable,
      'paidAmount': 0,
      'period': int.parse(_periodController.text.split(' ')[0]),
      'startDate': now.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': 'active',
    };

    await _dbService.insertTransaction({
      'id': _uuid.v4(),
      'groupId': widget.groupId,
      'memberId': _selectedMember!.id,
      'meetingId': widget.meetingData['id'],
      'type': 'loan_disbursement',
      'amount': amount,
      'description': 'Loan disbursement',
      'date': now.toIso8601String(),
    });

    // Update meeting data
    if (widget.meetingData['loanRequests'] == null) {
      widget.meetingData['loanRequests'] = [];
    }
    widget.meetingData['loanRequests'].add(loan);
    widget.meetingData['totalLoans'] =
        (widget.meetingData['totalLoans'] ?? 0) + amount;

    await _dbService.updateMeeting(widget.meetingData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loan request submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    setState(() {
      _amountController.clear();
      _periodController.clear();
      _selectedMember = null;
      _interestAmount = 0;
      _totalPayable = 0;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _periodController.dispose();
    super.dispose();
  }
}
