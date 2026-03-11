import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_provider.dart';
import 'register_screen.dart';
import '../dashboard/group_leader_dashboard.dart';
import '../dashboard/member_dashboard.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _umvaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithUmvaId(
        _umvaController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        final provider = Provider.of<AppStateProvider>(context, listen: false);
        provider.setCurrentUser(
          user['id'] as String,
          groupId: user['groupId'] as String?,
        );

        final role = user['role'] as String? ?? 'member';
        if (role == 'leader' || role == 'president') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const GroupLeaderDashboard()));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      MemberDashboard(memberId: user['id'] as String)));
        }
      } else {
        _showError(
            'Account not found. Please register or contact your group leader.');
      }
    } on FirebaseAuthError catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('No internet connection or server error. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedBank =
        Provider.of<AppStateProvider>(context).selectedBank ?? 'Bank';

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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance,
                              size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          Text(selectedBank,
                              style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Login to VSLA Desktop',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                    const SizedBox(height: 8),
                    Text('Enter your UMVA ID and password',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi,
                            size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text('Requires internet connection',
                            style: TextStyle(
                                fontSize: 12, color: Colors.green.shade600)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _umvaController,
                      label: 'UMVA ID',
                      hint: 'e.g., john.doe',
                      prefixIcon: Icons.person,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your UMVA ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
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
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                        text: 'LOGIN',
                        onPressed: _login,
                        isLoading: _isLoading),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('← Change Bank'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _umvaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
