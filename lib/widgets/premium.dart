import 'package:flutter/material.dart';

class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PremiumButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF03A1E4), Color(0xFF007FC0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A1E4).withValues(alpha: 0.35),
            blurRadius: 18, offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(28), child: child),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).cardTheme.color ?? Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const BackChip({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }
}
