import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final idC = TextEditingController(); // email or username
  bool loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      final data = await AuthService.instance.requestPasswordReset(idC.text.trim());
      if (!mounted) return;
      final token = data['token'] as String;
      final mask = (data['contact_mask'] ?? 'your email').toString();
      final debugCode = data['debug_code']?.toString();
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(token: token, contactMask: mask, debugCode: debugCode),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          const Text('Enter your email address or username. We’ll send a 6-digit code to verify it’s you.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          TextField(
            controller: idC,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address or Username',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 52,
            child: FilledButton(onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: Text(loading ? 'Please wait...' : 'Send Code'))),
        ],
      ),
    );
  }
}
