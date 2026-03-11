import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';

class PenaltiesScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;
  final String groupId;

  const PenaltiesScreen({
    super.key,
    required this.members,
    required this.meetingData,
    required this.groupId,
  });

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  Member? _selectedMember;
  String? _selectedPenalty;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService.instance;

  final List<Map<String, dynamic>> penaltyTypes = [
    {'name': 'Late Coming', 'amount': 1000},
    {'name': 'Absent without Notice', 'amount': 2000},
    {'name': 'Loud Talking', 'amount': 500},
    {'name': 'Phone Ringing', 'amount': 500},
    {'name': 'Not Wearing Badge', 'amount': 1000},
    {'name': 'Custom', 'amount': 0},
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

          // Penalty Details
          if (_selectedMember != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penalty Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Penalty type
                    DropdownButtonFormField<String>(
                      value: _selectedPenalty,
                      decoration: const InputDecoration(
                        labelText: 'Penalty Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          penaltyTypes.map<DropdownMenuItem<String>>((penalty) {
                        return DropdownMenuItem<String>(
                          value: penalty['name'] as String,
                          child: Text(
                              '${penalty['name']} - UGX ${penalty['amount']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPenalty = value;
                          var selected = penaltyTypes.firstWhere(
                            (p) => p['name'] == value,
                          );
                          if (selected['amount'] > 0) {
                            _amountController.text =
                                selected['amount'].toString();
                          } else {
                            _amountController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        prefixText: 'UGX ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: _submitPenalty,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Penalty'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitPenalty() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    if (_selectedPenalty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a penalty type')),
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

    // Create penalty record
    Map<String, dynamic> penalty = {
      'id': _uuid.v4(),
      'memberId': _selectedMember!.id,
      'groupId': widget.groupId,
      'meetingId': widget.meetingData['id'],
      'type': _selectedPenalty,
      'amount': amount,
      'description': _descriptionController.text,
      'paid': 0,
      'date': DateTime.now().toIso8601String(),
    };

    await _dbService.insertTransaction({
      'id': _uuid.v4(),
      'groupId': widget.groupId,
      'memberId': _selectedMember!.id,
      'meetingId': widget.meetingData['id'],
      'type': 'penalty',
      'amount': amount,
      'description': 'Penalty: $_selectedPenalty',
      'date': DateTime.now().toIso8601String(),
    });

    // Update meeting data
    if (widget.meetingData['penalties'] == null) {
      widget.meetingData['penalties'] = [];
    }
    widget.meetingData['penalties'].add(penalty);
    widget.meetingData['totalPenalties'] =
        (widget.meetingData['totalPenalties'] ?? 0) + amount;

    await _dbService.updateMeeting(widget.meetingData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Penalty applied successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    setState(() {
      _selectedPenalty = null;
      _amountController.clear();
      _descriptionController.clear();
      _selectedMember = null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
