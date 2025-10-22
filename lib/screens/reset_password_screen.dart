import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String contactMask; // e.g., j***@mail.com
  final String? debugCode;  // only in dev
  const ResetPasswordScreen({super.key, required this.token, required this.contactMask, this.debugCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codeC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();
  bool o1 = true, o2 = true;
  bool loading = false;

  Future<void> _submit() async {
    if (passC.text != pass2C.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService.instance.completePasswordReset(
        token: widget.token,
        code: codeC.text.trim(),
        newPassword: passC.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please log in.')));
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintDev = widget.debugCode==null ? '' : ' (DEV code: ${widget.debugCode})';
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Code')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Text('We sent a 6-digit code to ${widget.contactMask}.$hintDev', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          TextField(
            controller: codeC,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '6-digit Code',
              counterText: '',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passC, obscureText: o1,
            decoration: InputDecoration(
              labelText: 'New Password',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              suffixIcon: IconButton(onPressed: ()=>setState(()=>o1=!o1), icon: Icon(o1?Icons.visibility:Icons.visibility_off)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass2C, obscureText: o2,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              suffixIcon: IconButton(onPressed: ()=>setState(()=>o2=!o2), icon: Icon(o2?Icons.visibility:Icons.visibility_off)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 52,
            child: FilledButton(onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: Text(loading ? 'Please wait...' : 'Set New Password'))),
        ],
      ),
    );
  }
}
