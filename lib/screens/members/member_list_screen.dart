import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../members/member_registration_screen.dart';
import '../../utils/helpers.dart';

class MemberListScreen extends StatelessWidget {
  final List<Member> members;
  final String groupId;
  final bool showAddButton;

  const MemberListScreen({
    super.key,
    required this.members,
    required this.groupId,
    this.showAddButton = false,
  });

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'president': return Colors.purple;
      case 'treasurer': return Colors.green;
      case 'secretary': return Colors.orange;
      case 'leader': return Colors.red;
      default: return Colors.blue;
    }
  }

  void _showMemberDetails(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(member.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('UMVA ID', member.umvaId),
              _row('Gender', member.gender),
              _row('Phone', member.phone.isEmpty ? '-' : member.phone),
              _row('Address', member.address.isEmpty ? '-' : member.address),
              _row('Location',
                  [member.region, member.district].where((s) => s.isNotEmpty).join(', ')),
              const Divider(),
              _row('Savings', Helpers.formatCurrency(member.savingsBalance),
                  valueColor: Colors.blue),
              _row('Loan Balance',
                  Helpers.formatCurrency(member.loanBalance),
                  valueColor: Colors.orange),
              _row('Social Fund',
                  Helpers.formatCurrency(member.socialFundBalance),
                  valueColor: Colors.green),
              _row('Role', member.role.toUpperCase()),
              _row('Member Since',
                  Helpers.formatDate(member.registrationDate)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontWeight: valueColor != null
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members (${members.length})'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MemberRegistrationScreen(groupId: groupId),
              ),
            ),
            tooltip: 'Add Member',
          ),
        ],
      ),
      body: members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No members found',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberRegistrationScreen(groupId: groupId),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Member'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _roleColor(member.role),
                      child: Text(
                        member.firstName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(member.fullName,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UMVA: ${member.umvaId}'),
                        Text(
                          'Savings: ${Helpers.formatCurrency(member.savingsBalance)}',
                          style:
                              const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        member.role.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: _roleColor(member.role),
                      padding: EdgeInsets.zero,
                    ),
                    onTap: () => _showMemberDetails(context, member),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
