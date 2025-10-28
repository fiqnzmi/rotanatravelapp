import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Optional: callback selepas login berjaya.
  final VoidCallback? onAuthSuccess;

  const LoginScreen({super.key, this.onAuthSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idC = TextEditingController(); // email or username
  final passC = TextEditingController();
  bool obscure = true;
  bool loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await AuthService.instance
          .login(identifier: idC.text.trim(), password: passC.text);

      if (!mounted) return;

      // Jika callback diberi, biar parent handle navigasi tambahan.
      widget.onAuthSuccess?.call();
      // Sekiranya skrin ini masih aktif selepas callback, pop dengan 'true'
      // supaya pemanggil tahu login berjaya.
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 8))
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 5,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset('assets/images/rotana_logo.png'),
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                Text('Rotana Travel & Tours',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Log In',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _roundedField(
              controller: idC,
              label: 'Email Address or Username',
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _roundedField(
            controller: passC,
            label: 'Password',
            obscure: obscure,
            suffix: IconButton(
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                  shape: const StadiumBorder(), elevation: 2),
              child: Text(loading ? 'Please wait...' : 'Log In'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?  "),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupScreen(
                      onAuthSuccess: widget.onAuthSuccess, // nullable ok
                    ),
                  ),
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundedField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
