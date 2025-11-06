import 'package:flutter/material.dart';

typedef NotificationToggleCallback = Future<bool> Function(
  bool value,
  BuildContext context,
);

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.initialEmail,
    required this.initialSms,
    required this.onEmailChanged,
    required this.onSmsChanged,
  });

  final bool initialEmail;
  final bool initialSms;
  final NotificationToggleCallback onEmailChanged;
  final NotificationToggleCallback onSmsChanged;

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _emailEnabled = widget.initialEmail;
  late bool _smsEnabled = widget.initialSms;
  bool _saving = false;

  Future<void> _toggleEmail(bool value) async {
    if (_saving) return;
    final previous = _emailEnabled;
    setState(() {
      _emailEnabled = value;
      _saving = true;
    });
    final success = await widget.onEmailChanged(value, context);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _emailEnabled = previous;
        _saving = false;
      });
      return;
    }
    setState(() {
      _saving = false;
    });
  }

  Future<void> _toggleSms(bool value) async {
    if (_saving) return;
    final previous = _smsEnabled;
    setState(() {
      _smsEnabled = value;
      _saving = true;
    });
    final success = await widget.onSmsChanged(value, context);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _smsEnabled = previous;
        _saving = false;
      });
      return;
    }
    setState(() {
      _saving = false;
    });
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
            onChanged: _saving ? null : onChanged,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: ListView(
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
        ),
      ),
    );
  }
}
