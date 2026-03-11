import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/settings.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'signatory_settings_screen.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _shareValueController = TextEditingController(text: '1000');
  final _minShareUnitsController = TextEditingController(text: '1');
  final _maxShareUnitsController = TextEditingController(text: '5');
  final _minSocialFundController = TextEditingController(text: '500');
  final _interestRateController = TextEditingController(text: '30');
  final _maxLoanMultiplierController = TextEditingController(text: '3');
  final _minLoanPeriodController = TextEditingController(text: '4');
  final _maxLoanPeriodController = TextEditingController(text: '12');

  bool _solidarityFundCompulsory = true;
  bool _enablePenalties = true;
  bool _isLoading = false;
  String? _groupId;

  final _dbService = DatabaseService.instance;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _groupId = await _authService.getGroupId();

    if (_groupId != null) {
      final settings = await _dbService.getGroupSettings(_groupId!);
      if (settings != null) {
        _shareValueController.text = settings.shareValue.toString();
        _minShareUnitsController.text = settings.minShareUnits.toString();
        _maxShareUnitsController.text = settings.maxShareUnits.toString();
        _minSocialFundController.text = settings.minSocialFundAmount.toString();
        _interestRateController.text = settings.interestRate.toString();
        _maxLoanMultiplierController.text =
            settings.maxLoanMultiplier.toString();
        _minLoanPeriodController.text = settings.minLoanPeriod.toString();
        _maxLoanPeriodController.text = settings.maxLoanPeriod.toString();
        _solidarityFundCompulsory = settings.solidarityFundCompulsory;
        _enablePenalties = settings.enablePenalties;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final gId = _groupId ?? 'default-group';
      final existing = await _dbService.getGroupSettings(gId);

      final settings = GroupSettings(
        id: existing?.id ?? _uuid.v4(),
        groupId: gId,
        shareValue: double.parse(_shareValueController.text),
        minShareUnits: int.parse(_minShareUnitsController.text),
        maxShareUnits: int.parse(_maxShareUnitsController.text),
        minSocialFundAmount: double.parse(_minSocialFundController.text),
        solidarityFundCompulsory: _solidarityFundCompulsory,
        interestRate: double.parse(_interestRateController.text),
        maxLoanMultiplier: int.parse(_maxLoanMultiplierController.text),
        minLoanPeriod: int.parse(_minLoanPeriodController.text),
        maxLoanPeriod: int.parse(_maxLoanPeriodController.text),
        enablePenalties: _enablePenalties,
        updatedAt: DateTime.now(),
      );

      if (existing != null) {
        await _dbService.updateSettings(settings);
      } else {
        await _dbService.insertSettings(settings);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignatorySettingsScreen(groupId: gId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _numField(String label, TextEditingController ctrl,
      {String? prefix, String? suffix}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefix,
        suffixText: suffix,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These settings define the rules for your VSLA cycle. Enter carefully.',
                              style: TextStyle(
                                  color: Colors.blue.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shares
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Share Settings',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _numField(
                                'Value per Share (UGX)', _shareValueController,
                                prefix: 'UGX '),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _numField('Min Units/Meeting',
                                      _minShareUnitsController),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _numField('Max Units/Meeting',
                                      _maxShareUnitsController),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Social Fund
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Social Fund Settings',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _numField('Minimum Social Fund Contribution (UGX)',
                                _minSocialFundController,
                                prefix: 'UGX '),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                  'Solidarity Fund Compulsory for all'),
                              value: _solidarityFundCompulsory,
                              onChanged: (v) =>
                                  setState(() => _solidarityFundCompulsory = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loans
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Loan Settings',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _numField(
                                'Interest Rate (%)', _interestRateController,
                                suffix: '%'),
                            const SizedBox(height: 12),
                            _numField('Maximum Loan Multiplier (× savings)',
                                _maxLoanMultiplierController),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _numField('Min Period (weeks)',
                                      _minLoanPeriodController),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _numField('Max Period (weeks)',
                                      _maxLoanPeriodController),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Penalties
                    Card(
                      child: SwitchListTile(
                        title: const Text('Enable Penalties/Fines'),
                        value: _enablePenalties,
                        onChanged: (v) => setState(() => _enablePenalties = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('SAVE AND CONTINUE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _shareValueController.dispose();
    _minShareUnitsController.dispose();
    _maxShareUnitsController.dispose();
    _minSocialFundController.dispose();
    _interestRateController.dispose();
    _maxLoanMultiplierController.dispose();
    _minLoanPeriodController.dispose();
    _maxLoanPeriodController.dispose();
    super.dispose();
  }
}

extension AuthServiceGetGroupId on AuthService {
  /// Fallback implementation for getGroupId used by GroupSettingsScreen.
  /// Replace this with the real AuthService API integration if available.
  Future<String?> getGroupId() async {
    return null;
  }
}
