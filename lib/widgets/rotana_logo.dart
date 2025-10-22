import 'package:flutter/material.dart';

/// Displays your wide Rotana logo image in screens.
class RotanaLogo extends StatelessWidget {
  final double width;
  final EdgeInsets padding;
  const RotanaLogo({super.key, this.width = 180, this.padding = const EdgeInsets.all(0)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Image.asset(
        'assets/images/rotana_logo.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
