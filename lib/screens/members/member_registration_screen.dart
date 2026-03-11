import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class MemberRegistrationScreen extends StatefulWidget {
  final String groupId;
  const MemberRegistrationScreen({super.key, required this.groupId});

  @override
  State<MemberRegistrationScreen> createState() =>
      _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender;
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedConstituency;
  String? _selectedSubCounty;
  String? _selectedRole;
  bool _isLoading = false;
  String? _statusMessage;
  bool _statusIsError = false;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> districts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Gulu',
    'Mbale',
    'Mbarara',
    'Masaka',
    'Arua',
    'Fort Portal',
  ];
  final List<String> constituencies = [
    'Kampala Central',
    'Kawempe',
    'Makindye',
    'Nakawa',
    'Rubaga',
  ];
  final List<String> subCounties = [
    'Central Division',
    'Kyambogo',
    'Bwaise',
    'Kalerwe',
    'Kira',
  ];
  final List<String> roles = ['member', 'president', 'treasurer', 'secretary'];

  final _dbService = DatabaseService.instance;
  final _authService = AuthService();

  Future<void> _registerMember() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating member account online...';
      _statusIsError = false;
    });

    try {
      final umvaId = _authService.generateUmvaId(
        _firstNameController.text,
        _lastNameController.text,
      );
      final memberId = _uuid.v4();
      // Auto-generate a temporary password for the member
      final generatedPassword = Helpers.generateRandomPassword();

      // Step 1: Create Firebase account for the member (requires internet)
      final authResult = await (_authService as dynamic).registerUser(
        umvaId: umvaId,
        password: generatedPassword,
        groupId: widget.groupId,
        role: _selectedRole ?? 'member',
        memberId: memberId,
      );

      if (!authResult.success) {
        setState(() {
          _isLoading = false;
          _statusMessage = authResult.errorMessage;
          _statusIsError = true;
        });
        return;
      }

      setState(() => _statusMessage = 'Saving member locally...');

      // Step 2: Save member in local SQLite
      final member = Member(
        id: memberId,
        umvaId: umvaId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender ?? 'Male',
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        region: _selectedRegion ?? '',
        district: _selectedDistrict ?? '',
        constituency: _selectedConstituency ?? '',
        subCounty: _selectedSubCounty ?? '',
        groupId: widget.groupId,
        role: _selectedRole ?? 'member',
        registrationDate: DateTime.now(),
      );

      await _dbService.insertMember(member);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show credentials dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Member Registered'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share these credentials with the member:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UMVA ID',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Text(
                      umvaId,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 10),
                    Text('Temporary Password',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Text(
                      generatedPassword,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ The member should change their password after first login.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to member list
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Registration failed: $e';
          _statusIsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Member'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Status banner
              if (_statusMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _statusIsError
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusIsError
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isLoading && !_statusIsError)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _statusIsError
                              ? Icons.error_outline
                              : Icons.info_outline,
                          color: _statusIsError
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                          size: 18,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusIsError
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.people)),
                        items: genders
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                            labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                        items: roles
                            .map((r) => DropdownMenuItem(
                                value: r, child: Text(r.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRole = v),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        prefixIcon: Icons.location_on,
                        maxLines: 2,
                      ),
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
                      const Text('Location',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: const InputDecoration(
                            labelText: 'Region', prefixIcon: Icon(Icons.map)),
                        items: AppConstants.ugandaRegions
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRegion = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                            labelText: 'District',
                            prefixIcon: Icon(Icons.location_city)),
                        items: districts
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedDistrict = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedConstituency,
                        decoration: const InputDecoration(
                            labelText: 'Constituency',
                            prefixIcon: Icon(Icons.place)),
                        items: constituencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedConstituency = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSubCounty,
                        decoration: const InputDecoration(
                            labelText: 'Sub County',
                            prefixIcon: Icon(Icons.place_outlined)),
                        items: subCounties
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSubCounty = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'REGISTER MEMBER',
                onPressed: _isLoading ? null : _registerMember,
                isLoading: _isLoading,
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
    super.dispose();
  }
}
