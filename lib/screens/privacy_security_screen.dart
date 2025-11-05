import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _twoFactor = true;
  bool _biometricLogin = false;
  bool _rememberDevices = true;
  bool _showPersonalizedContent = true;
  bool _saving = false;

  Future<void> _toggleSetting(bool value, ValueSetter<bool> setter, String label) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      setter(value);
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label ${value ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    }
  }

  Future<void> _downloadData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download request submitted.')),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will remove your Rotana Travel account permanently. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion request received.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Security',
            children: [
              SwitchListTile(
                value: _twoFactor,
                onChanged: (value) =>
                    _toggleSetting(value, (val) => _twoFactor = val, 'Two-factor authentication'),
                title: const Text('Two-factor authentication'),
                subtitle: const Text('Adds an extra step when you login from a new device.'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _biometricLogin,
                onChanged: (value) => _toggleSetting(
                    value, (val) => _biometricLogin = val, 'Biometric login'),
                title: const Text('Biometric login'),
                subtitle: const Text('Use Face ID or fingerprint on supported devices.'),
              ),
              ListTile(
                title: const Text('Change password'),
                subtitle: const Text('Update your account password.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Privacy preferences',
            children: [
              SwitchListTile(
                value: _rememberDevices,
                onChanged: (value) => _toggleSetting(
                    value, (val) => _rememberDevices = val, 'Trusted devices'),
                title: const Text('Remember trusted devices'),
                subtitle: const Text('Skip verification on devices you frequently use.'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _showPersonalizedContent,
                onChanged: (value) => _toggleSetting(
                    value, (val) => _showPersonalizedContent = val, 'Personalized content'),
                title: const Text('Personalized recommendations'),
                subtitle: const Text('Use your preferences to tailor offers and packages.'),
              ),
              ListTile(
                title: const Text('Download my data'),
                trailing: const Icon(Icons.file_download_outlined),
                onTap: _downloadData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Danger zone',
            children: [
              ListTile(
                title: const Text(
                  'Delete account',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentC,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your current password' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newC,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Use at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmC,
              obscureText: _obscureNew,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (value) {
                if (value != _newC.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
