import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';

class LoanRepaymentScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;
  final String groupId;

  const LoanRepaymentScreen({
    super.key,
    required this.members,
    required this.meetingData,
    required this.groupId,
  });

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  Member? _selectedMember;
  final _repaymentController = TextEditingController();
  double _outstandingLoan = 0;
  double _remainingBalance = 0;
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService.instance;

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
                        _outstandingLoan = value?.loanBalance ?? 0;
                        _remainingBalance = _outstandingLoan;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Repayment Details
          if (_selectedMember != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repayment Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Outstanding loan
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Outstanding Loan:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'UGX ${_outstandingLoan.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Repayment amount
                    TextField(
                      controller: _repaymentController,
                      decoration: const InputDecoration(
                        labelText: 'Repayment Amount',
                        border: OutlineInputBorder(),
                        prefixText: 'UGX ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        double repayment = double.tryParse(value) ?? 0;
                        setState(() {
                          _remainingBalance = _outstandingLoan - repayment;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remaining balance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Remaining Balance:'),
                          Text(
                            'UGX ${_remainingBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _remainingBalance <= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
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
              onPressed: _submitRepayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Submit Repayment'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitRepayment() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    double repayment = double.tryParse(_repaymentController.text) ?? 0;
    if (repayment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (repayment > _outstandingLoan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repayment cannot exceed outstanding loan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update member loan balance
    _selectedMember!.loanBalance -= repayment;
    await _dbService.updateMember(_selectedMember!);

    // Create transaction
    await _dbService.insertTransaction({
      'id': _uuid.v4(),
      'groupId': widget.groupId,
      'memberId': _selectedMember!.id,
      'meetingId': widget.meetingData['id'],
      'type': 'loan_repayment',
      'amount': repayment,
      'description': 'Loan repayment',
      'date': DateTime.now().toIso8601String(),
    });

    // Update meeting data
    if (widget.meetingData['loanRepayments'] == null) {
      widget.meetingData['loanRepayments'] = [];
    }
    widget.meetingData['loanRepayments'].add({
      'memberId': _selectedMember!.id,
      'amount': repayment,
      'date': DateTime.now().toIso8601String(),
    });

    await _dbService.updateMeeting(widget.meetingData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repayment recorded successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    setState(() {
      _repaymentController.clear();
      _selectedMember = null;
      _outstandingLoan = 0;
      _remainingBalance = 0;
    });
  }

  @override
  void dispose() {
    _repaymentController.dispose();
    super.dispose();
  }
}
