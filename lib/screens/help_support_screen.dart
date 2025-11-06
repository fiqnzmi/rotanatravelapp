import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageC = TextEditingController();
  final _subjectC = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageC.dispose();
    _subjectC.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final message = _messageC.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _messageC.clear();
      _subjectC.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support request submitted. We will reply soon.')),
    );
  }

  void _showContactSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Contact us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('support@rotanatravel.com'),
                subtitle: Text('Send us an email anytime.'),
              ),
              ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('+60 11-3713 6259'),
                subtitle: Text('Monday – Friday, 9am to 6pm'),
              ),
              ListTile(
                leading: Icon(Icons.chat_outlined),
                title: Text('Live chat'),
                subtitle: Text('Available in the Trips tab during office hours.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = [
      const _FaqItem(
        question: 'How can I change my travel dates?',
        answer:
            'Open your booking in the Trips tab, tap “Modify booking”, and request your preferred dates. Our team will confirm availability.',
      ),
      const _FaqItem(
        question: 'What documents do I need for Umrah packages?',
        answer:
            'You will need a passport valid for at least 6 months, meningitis vaccination certificate, and completed visa application form. We will guide you through each step.',
      ),
      const _FaqItem(
        question: 'How do I pay the remaining balance?',
        answer:
            'Go to “My Bookings”, select the trip, and choose “Pay balance”. You can pay with saved cards, FPX, or bank transfer.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: _showContactSheet,
            tooltip: 'Contact options',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular questions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...faqs.map((item) => _FaqExpansion(item: item)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send us a message',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectC,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageC,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'How can we help?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submitTicket,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our support team replies within 24 hours. For urgent travel changes, please call us directly.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqExpansion extends StatefulWidget {
  const _FaqExpansion({required this.item});
  final _FaqItem item;

  @override
  State<_FaqExpansion> createState() => _FaqExpansionState();
}

class _FaqExpansionState extends State<_FaqExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(widget.item.question),
          trailing: Icon(_expanded ? Icons.remove_circle_outline : Icons.add_circle_outline),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.item.answer,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
