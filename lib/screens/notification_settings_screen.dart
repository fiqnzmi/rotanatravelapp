import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/error_utils.dart';
import 'login_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _svc = DashboardService();

  bool _loading = true;
  bool _saving = false;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  int? _userId;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _ensureLoggedIn() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (loggedIn) return;
    if (!mounted) return;
    final proceed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (proceed != true) {
      throw Exception('Login required to update notifications.');
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _ensureLoggedIn();
      final id = await AuthService.instance.getUserId();
      if (id == null) {
        throw Exception('Unable to determine your user id.');
      }
      final payload = await _svc.profileOverview(id);
      final user = Map<String, dynamic>.from(payload['user'] as Map? ?? const {});
      final email = _parseBool(
        user['notify_email'] ??
            user['email_notifications'] ??
            user['pref_email'] ??
            user['notification_email'],
        fallback: true,
      );
      final sms = _parseBool(
        user['notify_sms'] ??
            user['sms_notifications'] ??
            user['pref_sms'] ??
            user['notification_sms'],
        fallback: false,
      );
      if (!mounted) return;
      setState(() {
        _userId = id;
        _emailEnabled = email;
        _smsEnabled = sms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEmail(bool value) => _updateSettings(email: value);
  Future<void> _toggleSms(bool value) => _updateSettings(sms: value);

  Future<void> _updateSettings({bool? email, bool? sms}) async {
    if (_saving || _userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final previousEmail = _emailEnabled;
    final previousSms = _smsEnabled;

    setState(() {
      if (email != null) _emailEnabled = email;
      if (sms != null) _smsEnabled = sms;
      _saving = true;
    });

    try {
      await _svc.updateProfile({
        'user_id': '${_userId!}',
        if (email != null) 'notify_email': email ? '1' : '0',
        if (sms != null) 'notify_sms': sms ? '1' : '0',
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification preferences updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (email != null) _emailEnabled = previousEmail;
        if (sms != null) _smsEnabled = previousSms;
        _saving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update notifications: ${friendlyError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget buildTile({
      required bool value,
      required Future<void> Function(bool) onChanged,
      required String title,
      required String subtitle,
    }) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
            ],
          ),
          child: SwitchListTile.adaptive(
            value: value,
            onChanged: (_saving || _loading) ? null : onChanged,
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          ),
        ),
      );
    }

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                friendlyError(_loadError!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadSettings,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_saving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          buildTile(
            value: _emailEnabled,
            onChanged: _toggleEmail,
            title: 'Email updates',
            subtitle: 'Receive booking reminders and payment receipts by email.',
          ),
          const SizedBox(height: 14),
          buildTile(
            value: _smsEnabled,
            onChanged: _toggleSms,
            title: 'SMS alerts',
            subtitle: 'Get important travel alerts via SMS.',
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(child: body),
    );
  }

  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed.isEmpty) return fallback;
      if (trimmed == '1' || trimmed == 'true' || trimmed == 'yes' || trimmed == 'y' || trimmed == 'on') {
        return true;
      }
      if (trimmed == '0' || trimmed == 'false' || trimmed == 'no' || trimmed == 'n' || trimmed == 'off') {
        return false;
      }
    }
    return fallback;
  }
}
