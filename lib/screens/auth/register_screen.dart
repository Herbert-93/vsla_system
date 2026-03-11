import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_provider.dart';
import '../../models/member.dart';
import '../../models/group.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _groupCodeController = TextEditingController();
  final _joinGroupCodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedRegion;
  String? _selectedDistrict;

  bool _isCreatingGroup = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> regions = ['Central', 'Eastern', 'Northern', 'Western'];
  final List<String> districts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Gulu',
    'Mbale',
    'Mbarara',
    'Masaka',
  ];

  final DatabaseService _dbService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedBank =
          Provider.of<AppStateProvider>(context, listen: false).selectedBank ??
              'Unknown Bank';

      final umvaId = _authService.generateUmvaId(
        _firstNameController.text,
        _lastNameController.text,
      );

      final uid = await _authService.createFirebaseAccount(
        umvaId: umvaId,
        password: _passwordController.text,
      );

      String groupId;
      String role;

      if (_isCreatingGroup) {
        groupId = _uuid.v4();
        role = 'leader';

        final group = Group(
          id: groupId,
          name: _groupNameController.text.trim(),
          groupCode: _groupCodeController.text.trim(),
          bankName: selectedBank,
          formationDate: DateTime.now(),
          presidentId: uid,
          treasurerId: '',
          secretaryId: '',
        );
        await _dbService.insertGroup(group);
      } else {
        final code = _joinGroupCodeController.text.trim();
        final db = await _dbService.database;
        final groups = await db.query('groups',
            where: 'groupCode = ?', whereArgs: [code], limit: 1);

        if (groups.isEmpty) {
          setState(() => _isLoading = false);
          _showError('Group code "$code" not found. Check with your leader.');
          return;
        }
        final existingGroupMap = groups.first;
        groupId = existingGroupMap['id'] as String;
        role = 'member';
      }

      final db = await _dbService.database;
      final existingMember =
          await db.query('members', where: 'umvaId = ?', whereArgs: [umvaId]);

      if (existingMember.isNotEmpty) {
        await db.update('members', {'id': uid},
            where: 'umvaId = ?', whereArgs: [umvaId]);
      } else {
        final member = Member(
          id: uid,
          umvaId: umvaId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          gender: _selectedGender ?? 'Male',
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          region: _selectedRegion ?? '',
          district: _selectedDistrict ?? '',
          constituency: '',
          subCounty: '',
          groupId: groupId,
          role: role,
          registrationDate: DateTime.now(),
        );
        await _dbService.insertMember(member);
      }

      await _authService.saveRegistrationSession(
        uid: uid,
        umvaId: umvaId,
        groupId: groupId,
        role: role,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog(umvaId);
    } on FirebaseAuthError catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Registration failed. Check your internet connection.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5)),
    );
  }

  void _showSuccessDialog(String umvaId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Registration Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your VSLA account has been created.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your UMVA ID:',
                      style: TextStyle(color: Colors.blue.shade800)),
                  SelectableText(umvaId,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Use this to login from any device.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK — Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create VSLA Account'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Internet connection required to create your account.',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account Type',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Create New Group'),
                              subtitle: const Text('Group Leader'),
                              value: true,
                              groupValue: _isCreatingGroup,
                              onChanged: (v) =>
                                  setState(() => _isCreatingGroup = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Join Existing Group'),
                              subtitle: const Text('Member'),
                              value: false,
                              groupValue: _isCreatingGroup,
                              onChanged: (v) =>
                                  setState(() => _isCreatingGroup = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isCreatingGroup) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Group Information',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _groupNameController,
                          label: 'Group Name',
                          prefixIcon: Icons.group,
                          validator: (v) =>
                              (_isCreatingGroup && (v == null || v.isEmpty))
                                  ? 'Enter group name'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _groupCodeController,
                          label: 'Group Code (unique)',
                          hint: 'e.g., UGAFODE-KLA-001',
                          prefixIcon: Icons.code,
                          validator: (v) =>
                              (_isCreatingGroup && (v == null || v.isEmpty))
                                  ? 'Enter a unique group code'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join a Group',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Ask your group leader for the group code.',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _joinGroupCodeController,
                          label: 'Group Code',
                          prefixIcon: Icons.vpn_key,
                          validator: (v) =>
                              (!_isCreatingGroup && (v == null || v.isEmpty))
                                  ? 'Enter your group code'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Information',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        prefixIcon: Icons.person,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter first name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter last name' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.people),
                        ),
                        items: genders
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v),
                        validator: (v) => (v == null) ? 'Select gender' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        prefixIcon: Icons.location_on,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: InputDecoration(
                          labelText: 'Region',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.map),
                        ),
                        items: regions
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRegion = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                        items: districts
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedDistrict = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Set Your Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_firstNameController, _lastNameController]),
                        builder: (_, __) => Text(
                          'Your UMVA ID will be: '
                          '${_firstNameController.text.isEmpty ? 'firstname' : _firstNameController.text.toLowerCase()}'
                          '.'
                          '${_lastNameController.text.isEmpty ? 'lastname' : _lastNameController.text.toLowerCase()}',
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                  text: 'CREATE ACCOUNT',
                  onPressed: _register,
                  isLoading: _isLoading),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _groupNameController.dispose();
    _groupCodeController.dispose();
    _joinGroupCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
