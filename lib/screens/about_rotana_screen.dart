import 'package:flutter/material.dart';

class AboutRotanaScreen extends StatelessWidget {
  const AboutRotanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final highlights = [
      _Highlight(
        icon: Icons.card_travel,
        title: '30+ curated travel packages',
        description:
            'From Umrah experiences to halal family vacations, we handpick trusted partners across the globe.',
      ),
      _Highlight(
        icon: Icons.support_agent,
        title: 'Dedicated travel concierge',
        description:
            'Our team is available to help you plan, book, and manage every detail of your journey.',
      ),
      _Highlight(
        icon: Icons.security,
        title: 'Licensed & insured',
        description:
            'Rotana Travel & Tours is a registered Malaysian travel agency with full insurance coverage.',
      ),
    ];

    final timeline = [
      const _TimelineEntry(year: '2016', detail: 'Rotana Travel & Tours founded in Kuala Lumpur.'),
      const _TimelineEntry(year: '2018', detail: 'Launched digital booking assistant for Umrah packages.'),
      const _TimelineEntry(year: '2020', detail: 'Expanded to Europe and Central Asia tours.'),
      const _TimelineEntry(year: '2023', detail: 'Introduced mobile app with instant booking confirmation.'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Rotana'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rotana Travel & Tours',
                  style: theme
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'We are passionate about creating meaningful journeys for pilgrims, families, and adventurers. '
                  'Our mission is to make travel planning effortless with transparent pricing, verified partners, '
                  'and caring support every step of the way.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HQ: Cheras Business Centre, 56100 Kuala Lumpur, Malaysia',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.language_outlined, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'www.rotanatravel.com',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.mail_outline, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'hello@rotanatravel.com',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...highlights.map((h) => _HighlightCard(highlight: h)).toList(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our journey',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...timeline.map((entry) => _TimelineTile(entry: entry)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF0E8AE8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Looking ahead',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We continue to invest in technology and partnerships that bring Rotana travellers the best value. '
                    'Expect richer destination guides, smarter personalization, and dedicated travel concierge services.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'App version 2.1.0',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Highlight {
  final IconData icon;
  final String title;
  final String description;

  const _Highlight({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});
  final _Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accentBackground = scheme.primaryContainer.withOpacity(
      theme.brightness == Brightness.dark ? 0.4 : 1,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accentBackground,
            child: Icon(highlight.icon, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  highlight.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry {
  final String year;
  final String detail;
  const _TimelineEntry({required this.year, required this.detail});
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});
  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF0E8AE8),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: const Color(0xFFB3E5FC),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.year,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(entry.detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
