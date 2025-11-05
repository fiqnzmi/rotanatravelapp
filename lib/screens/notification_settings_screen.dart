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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _emailEnabled,
                    onChanged: _saving ? null : (value) => _toggleEmail(value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email updates'),
                    subtitle: const Text('Receive booking reminders and payment receipts by email.'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: _smsEnabled,
                    onChanged: _saving ? null : (value) => _toggleSms(value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('SMS alerts'),
                    subtitle: const Text('Get important travel alerts via SMS.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
