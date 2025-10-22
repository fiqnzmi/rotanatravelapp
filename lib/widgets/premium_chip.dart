import 'package:flutter/material.dart';

class PremiumChip extends StatelessWidget {
  final String label;
  const PremiumChip({super.key, this.label = 'Premium'});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.workspace_premium_outlined, size: 16),
        SizedBox(width: 6),
        Text('Premium', style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
