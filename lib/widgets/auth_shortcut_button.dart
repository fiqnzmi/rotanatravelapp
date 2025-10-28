import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/profile_screen.dart';

/// Butang akaun di AppBar.
/// - Jika belum login: buka sheet dengan pilihan Log In / Sign Up.
/// - Jika sudah login : pergi terus ke Profile.
class AuthShortcutButton extends StatelessWidget {
  const AuthShortcutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () async {
        final isLoggedIn = await AuthService.instance.isLoggedIn();
        if (!context.mounted) return;
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else {
          _showAuthShortcutSheet(context);
        }
      },
    );
  }

  // Bottom sheet: Login / Sign Up
  static void _showAuthShortcutSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 40),
              const SizedBox(height: 8),
              Text(
                'Welcome to Rotana',
                style: Theme.of(parentContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Log in to manage trips, payments and documents.',
                textAlign: TextAlign.center,
                style: Theme.of(parentContext)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Log In
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Log In'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final loggedIn = await Navigator.of(parentContext).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (loggedIn == true && parentContext.mounted) {
                      Navigator.of(parentContext).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Sign Up
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Sign Up'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final registered = await Navigator.of(parentContext).push<bool>(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                    if (registered == true && parentContext.mounted) {
                      Navigator.of(parentContext).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        );
      },
    );
  }
}
