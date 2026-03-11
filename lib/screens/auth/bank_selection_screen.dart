import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';

class BankSelectionScreen extends StatefulWidget {
  const BankSelectionScreen({super.key});

  @override
  State<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends State<BankSelectionScreen> {
  String? selectedBank;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade200],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 60,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'VSLA Desktop',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Village Savings and Loans Association',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select your bank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBank,
                        hint: const Text('Choose a bank'),
                        isExpanded: true,
                        items: AppConstants.ugandaBanks
                            .map((bank) => DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedBank = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Get Started',
                    onPressed: selectedBank == null
                        ? null
                        : () async {
                            await _authService.setSelectedBank(selectedBank!);
                            if (!mounted) return;
                            Provider.of<AppStateProvider>(context,
                                    listen: false)
                                .setSelectedBank(selectedBank!);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
