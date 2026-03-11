import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/helpers.dart';
import '../../models/member.dart';

class SignatorySettingsScreen extends StatefulWidget {
  final String groupId;
  const SignatorySettingsScreen({super.key, required this.groupId});

  @override
  State<SignatorySettingsScreen> createState() =>
      _SignatorySettingsScreenState();
}

class _SignatorySettingsScreenState extends State<SignatorySettingsScreen> {
  final _presidentController = TextEditingController();
  final _treasurerController = TextEditingController();
  final _secretaryController = TextEditingController();
  bool _obscureAll = true;
  final _dbService = DatabaseService.instance;

  Future<void> _saveSignatories() async {
    if (_presidentController.text.isEmpty ||
        _treasurerController.text.isEmpty ||
        _secretaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set passwords for all signatories'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final members = await _dbService.getGroupMembers(widget.groupId);

      if (members.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No members found in this group. Please add members first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Find members by role safely — returns null if not found
      Member? _findByRole(String role) {
        try {
          return members.firstWhere((m) => m.role == role);
        } catch (_) {
          return null;
        }
      }

      final president =
          _findByRole('president') ?? _findByRole('leader') ?? members.first;
      final treasurer = _findByRole('treasurer') ??
          (members.length > 1 ? members[1] : members.first);
      final secretary = _findByRole('secretary') ??
          (members.length > 2 ? members[2] : members.first);

      await _dbService.setMemberPassword(
          president.id!, Helpers.hashPassword(_presidentController.text));
      await _dbService.setMemberPassword(
          treasurer.id!, Helpers.hashPassword(_treasurerController.text));
      await _dbService.setMemberPassword(
          secretary.id!, Helpers.hashPassword(_secretaryController.text));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signatories configured successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signatories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _signatoryCard(
    String title,
    TextEditingController ctrl,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: _obscureAll,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureAll ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureAll = !_obscureAll),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signatory Setup'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set verification passwords for the three signatories. They will be required to end each meeting.',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _signatoryCard('President / Chairperson', _presidentController,
                Icons.person, Colors.purple),
            const SizedBox(height: 8),
            _signatoryCard('Treasurer', _treasurerController,
                Icons.account_balance, Colors.green),
            const SizedBox(height: 8),
            _signatoryCard('Secretary', _secretaryController, Icons.description,
                Colors.orange),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSignatories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _presidentController.dispose();
    _treasurerController.dispose();
    _secretaryController.dispose();
    super.dispose();
  }
}
