import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/privacy_service.dart';
import '../utils/error_utils.dart';
import 'login_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final PrivacyService _service = PrivacyService();

  bool _twoFactor = false;
  bool _biometricLogin = false;
  bool _rememberDevices = true;
  bool _personalized = true;
  bool _saving = false;
  bool _loading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final id = await AuthService.instance.getUserId();
    if (!mounted) return;
    if (id == null) {
      setState(() {
        _userId = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _userId = id;
      _loading = true;
    });
    try {
      final settings = await _service.fetch(id);
      if (!mounted) return;
      setState(() {
        _twoFactor = settings.twoFactor;
        _biometricLogin = settings.biometricLogin;
        _rememberDevices = settings.trustedDevices;
        _personalized = settings.personalizedRecommendations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: ${friendlyError(e)}')),
      );
    }
  }

  Future<int?> _requireUserId() async {
    if (_userId != null) return _userId;
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (proceed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to manage settings.')),
        );
        return null;
      }
    }
    final id = await AuthService.instance.getUserId();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to retrieve your account id.')),
      );
      return null;
    }
    setState(() => _userId = id);
    return id;
  }

  Future<void> _updateSetting({
    required String label,
    required bool newValue,
    required Future<PrivacySettings> Function(int userId) request,
    required VoidCallback applyValue,
    required VoidCallback revertValue,
  }) async {
    final userId = await _requireUserId();
    if (userId == null) return;

    setState(() {
      _saving = true;
      applyValue();
    });
    try {
      final updated = await request(userId);
      if (!mounted) return;
      setState(() {
        _twoFactor = updated.twoFactor;
        _biometricLogin = updated.biometricLogin;
        _rememberDevices = updated.trustedDevices;
        _personalized = updated.personalizedRecommendations;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label ${newValue ? 'enabled' : 'disabled'}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        revertValue();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $label: ${friendlyError(e)}')),
      );
    }
  }

  Future<void> _changePassword() async {
    final userId = await _requireUserId();
    if (userId == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null) return;

    setState(() => _saving = true);
    try {
      await _service.changePassword(
        userId: userId,
        currentPassword: result['current']!,
        newPassword: result['new']!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: ${friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _downloadData() async {
    final userId = await _requireUserId();
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final path = await _service.downloadUserData(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download data: ${friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final userId = await _requireUserId();
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently remove your account and all associated data. Do you want to continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordPromptDialog(),
    );
    if (password == null || password.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _service.deleteAccount(userId: userId, password: password);
      await AuthService.instance.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${friendlyError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Security',
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _twoFactor,
                        onChanged: _saving
                            ? null
                            : (value) {
                                final previous = _twoFactor;
                                _updateSetting(
                                  label: 'Two-factor authentication',
                                  newValue: value,
                                  request: (id) => _service.update(id, twoFactor: value),
                                  applyValue: () => _twoFactor = value,
                                  revertValue: () => _twoFactor = previous,
                                );
                              },
                        title: const Text('Two-factor authentication'),
                        subtitle: const Text(
                          'Adds an extra step when you login from a new device.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _biometricLogin,
                        onChanged: _saving
                            ? null
                            : (value) {
                                final previous = _biometricLogin;
                                _updateSetting(
                                  label: 'Biometric login',
                                  newValue: value,
                                  request: (id) => _service.update(id, biometricLogin: value),
                                  applyValue: () => _biometricLogin = value,
                                  revertValue: () => _biometricLogin = previous,
                                );
                              },
                        title: const Text('Biometric login'),
                        subtitle: const Text('Use Face ID or fingerprint on supported devices.'),
                      ),
                      ListTile(
                        title: const Text('Change password'),
                        subtitle: const Text('Update your account password.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _saving ? null : _changePassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Privacy preferences',
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _rememberDevices,
                        onChanged: _saving
                            ? null
                            : (value) {
                                final previous = _rememberDevices;
                                _updateSetting(
                                  label: 'Trusted devices',
                                  newValue: value,
                                  request: (id) => _service.update(id, trustedDevices: value),
                                  applyValue: () => _rememberDevices = value,
                                  revertValue: () => _rememberDevices = previous,
                                );
                              },
                        title: const Text('Remember trusted devices'),
                        subtitle: const Text('Skip verification on devices you frequently use.'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _personalized,
                        onChanged: _saving
                            ? null
                            : (value) {
                                final previous = _personalized;
                                _updateSetting(
                                  label: 'Personalized content',
                                  newValue: value,
                                  request: (id) => _service.update(
                                      id, personalizedRecommendations: value),
                                  applyValue: () => _personalized = value,
                                  revertValue: () => _personalized = previous,
                                );
                              },
                        title: const Text('Personalized recommendations'),
                        subtitle: const Text(
                          'Use your preferences to tailor offers and packages.',
                        ),
                      ),
                      ListTile(
                        title: const Text('Download my data'),
                        trailing: const Icon(Icons.file_download_outlined),
                        onTap: _saving ? null : _downloadData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Danger zone',
                  child: ListTile(
                    title: const Text(
                      'Delete account',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                    onTap: _saving ? null : _deleteAccount,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          child,
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

  @override
  void dispose() {
    _currentC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      'current': _currentC.text.trim(),
      'new': _newC.text.trim(),
    });
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
                if (value == null || value.isEmpty) return 'Enter a new password';
                if (value.length < 8) return 'Use at least 8 characters';
                if (value == _currentC.text) return 'New password must be different';
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Update')),
      ],
    );
  }
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Password'),
      content: TextField(
        controller: _controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
