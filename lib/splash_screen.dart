import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart' show RootShell;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _c.forward();

    // Short delay then jump to app shell (dashboard/home)
    Timer(const Duration(milliseconds: 900), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RootShell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/rotana_logo.png',
                  width: 300,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 10),
                Text(
                  'Kembara Jiwa, Terapi Rohani',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
