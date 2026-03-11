import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';

class SocialFundScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;
  final String groupId;

  const SocialFundScreen({
    super.key,
    required this.members,
    required this.meetingData,
    required this.groupId,
  });

  @override
  State<SocialFundScreen> createState() => _SocialFundScreenState();
}

class _SocialFundScreenState extends State<SocialFundScreen> {
  late Map<String, TextEditingController> collectionControllers;
  late Map<String, TextEditingController> distributionControllers;
  bool _showCollection = true;
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    collectionControllers = {};
    distributionControllers = {};

    // Initialize controllers
    for (var member in widget.members) {
      collectionControllers[member.id!] = TextEditingController();
      distributionControllers[member.id!] = TextEditingController();
    }

    // Load existing data
    if (widget.meetingData['socialFundCollections'] != null) {
      var collections = widget.meetingData['socialFundCollections'];
      collections.forEach((memberId, amount) {
        if (collectionControllers.containsKey(memberId)) {
          collectionControllers[memberId]?.text = amount.toString();
        }
      });
    }
  }

  Future<void> _saveCollections() async {
    double totalCollected = 0;
    Map<String, double> collections = {};

    for (var member in widget.members) {
      if (collectionControllers[member.id]?.text.isNotEmpty ?? false) {
        double amount =
            double.tryParse(collectionControllers[member.id]!.text) ?? 0;
        if (amount > 0) {
          collections[member.id!] = amount;
          totalCollected += amount;

          // Create transaction
          await _dbService.insertTransaction({
            'id': _uuid.v4(),
            'groupId': widget.groupId,
            'memberId': member.id,
            'meetingId': widget.meetingData['id'],
            'type': 'social_fund_contribution',
            'amount': amount,
            'description': 'Social Fund Contribution',
            'date': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    widget.meetingData['socialFundCollections'] = collections;
    widget.meetingData['totalSocialFund'] =
        (widget.meetingData['totalSocialFund'] ?? 0) + totalCollected;

    await _dbService.updateMeeting(widget.meetingData);
  }

  Future<void> _saveDistributions() async {
    double totalDistributed = 0;
    Map<String, double> distributions = {};

    for (var member in widget.members) {
      if (distributionControllers[member.id]?.text.isNotEmpty ?? false) {
        double amount =
            double.tryParse(distributionControllers[member.id]!.text) ?? 0;
        if (amount > 0) {
          distributions[member.id!] = amount;
          totalDistributed += amount;

          // Create transaction
          await _dbService.insertTransaction({
            'id': _uuid.v4(),
            'groupId': widget.groupId,
            'memberId': member.id,
            'meetingId': widget.meetingData['id'],
            'type': 'social_fund_distribution',
            'amount': amount,
            'description': 'Social Fund Distribution',
            'date': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    widget.meetingData['socialFundDistributions'] = distributions;
    widget.meetingData['totalSocialFund'] =
        (widget.meetingData['totalSocialFund'] ?? 0) - totalDistributed;

    await _dbService.updateMeeting(widget.meetingData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showCollection = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _showCollection ? Colors.blue : Colors.grey,
                  ),
                  child: const Text('Collection'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveCollections().then((_) {
                      setState(() {
                        _showCollection = false;
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !_showCollection ? Colors.blue : Colors.grey,
                  ),
                  child: const Text('Distribution'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _showCollection
              ? _buildCollectionView()
              : _buildDistributionView(),
        ),
      ],
    );
  }

  Widget _buildCollectionView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        return Card(
          child: ListTile(
            title: Text(member.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UMVA: ${member.umvaId}'),
                const SizedBox(height: 8),
                TextField(
                  controller: collectionControllers[member.id],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'UGX ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Auto-save or validate
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDistributionView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        return Card(
          child: ListTile(
            title: Text(member.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Balance: UGX ${member.socialFundBalance}'),
                const SizedBox(height: 8),
                TextField(
                  controller: distributionControllers[member.id],
                  decoration: const InputDecoration(
                    labelText: 'Amount to Distribute',
                    border: OutlineInputBorder(),
                    prefixText: 'UGX ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in collectionControllers.values) {
      controller.dispose();
    }
    for (var controller in distributionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
