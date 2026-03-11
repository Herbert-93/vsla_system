import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';

class SavingsScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;
  final String groupId;

  const SavingsScreen({
    super.key,
    required this.members,
    required this.meetingData,
    required this.groupId,
  });

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late Map<String, TextEditingController> unitControllers;
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService.instance;
  double shareValue = 1000; // Should come from settings

  @override
  void initState() {
    super.initState();
    unitControllers = {};

    // Initialize controllers
    for (var member in widget.members) {
      unitControllers[member.id!] = TextEditingController();
    }
  }

  Future<void> _saveSavings() async {
    double totalSavings = 0;

    for (var member in widget.members) {
      if (unitControllers[member.id]?.text.isNotEmpty ?? false) {
        int units = int.tryParse(unitControllers[member.id]!.text) ?? 0;
        if (units > 0 && units <= 5) {
          // Max 5 units per meeting
          double amount = units * shareValue;
          totalSavings += amount;

          // Update member balance
          member.savingsBalance += amount;
          await _dbService.updateMember(member);

          // Create transaction
          await _dbService.insertTransaction({
            'id': _uuid.v4(),
            'groupId': widget.groupId,
            'memberId': member.id,
            'meetingId': widget.meetingData['id'],
            'type': 'savings',
            'amount': amount,
            'description': 'Purchased $units shares',
            'date': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    widget.meetingData['savings'] =
        unitControllers.map((key, value) => MapEntry(key, value.text));
    widget.meetingData['totalSavings'] =
        (widget.meetingData['totalSavings'] ?? 0) + totalSavings;

    await _dbService.updateMeeting(widget.meetingData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Savings recorded: UGX $totalSavings'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share Value: UGX $shareValue per unit. Members can purchase 1-5 units per meeting.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              member.firstName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('UMVA: ${member.umvaId}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Current Savings: UGX ${member.savingsBalance.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: unitControllers[member.id],
                              decoration: const InputDecoration(
                                labelText: 'Share Units (1-5)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '= UGX ${(int.tryParse(unitControllers[member.id]?.text ?? '0') ?? 0) * shareValue}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveSavings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Savings'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in unitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
