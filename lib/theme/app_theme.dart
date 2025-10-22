import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF03A1E4);

  static ThemeData light = _base(Brightness.light);
  static ThemeData dark  = _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: brandBlue, brightness: b);
    final text   = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      scaffoldBackgroundColor:
          b == Brightness.light ? const Color(0xFFF6F8FA) : const Color(0xFF0B1218),

      // premium cards
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
      ),

      // inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b == Brightness.light ? Colors.white : scheme.surface.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: brandBlue, width: 2.4),
        ),
      ),

      // buttons (pill + soft shadow)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: brandBlue.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: brandBlue.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          side: const BorderSide(color: brandBlue, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .2),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: b == Brightness.light ? Colors.white : scheme.surface,
        indicatorColor: brandBlue.withValues(alpha: .12),
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
