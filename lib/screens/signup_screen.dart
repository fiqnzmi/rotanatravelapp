import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/error_utils.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const SignupScreen({super.key, this.onAuthSuccess});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();
  bool obscure1 = true;
  bool obscure2 = true;
  bool agree = true;
  bool loading = false;

  Future<void> _submit() async {
    if (!agree) {
      _toast('Please agree to the Terms & Privacy Policy');
      return;
    }
    if (passC.text != pass2C.text) {
      _toast('Passwords do not match');
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.instance.register(
        username: usernameC.text.trim(),
        email: emailC.text.trim(),
        password: passC.text,
      );

      if (!mounted) return;

      widget.onAuthSuccess?.call();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
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
                Text(
                  'Rotana Travel & Tours',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an Account',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _roundedField(controller: usernameC, label: 'Username'),
          const SizedBox(height: 12),
          _roundedField(
            controller: emailC,
            label: 'Email Address',
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _roundedField(
            controller: passC,
            label: 'Password',
            obscure: obscure1,
            suffix: IconButton(
              onPressed: () => setState(() => obscure1 = !obscure1),
              icon: Icon(
                obscure1 ? Icons.visibility : Icons.visibility_off,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _roundedField(
            controller: pass2C,
            label: 'Confirm Password',
            obscure: obscure2,
            suffix: IconButton(
              onPressed: () => setState(() => obscure2 = !obscure2),
              icon: Icon(
                obscure2 ? Icons.visibility : Icons.visibility_off,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(value: agree, onChanged: (v) => setState(() => agree = v ?? false)),
              Expanded(
                child: Text(
                  'I agree to the Terms & Privacy Policy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(shape: const StadiumBorder(), elevation: 2),
              child: Text(loading ? 'Please wait...' : 'Create Account'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?  '),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Log In'),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fillColor = theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? scheme.surfaceVariant.withOpacity(0.55)
            : scheme.surface);
    final borderColor = scheme.outlineVariant;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
