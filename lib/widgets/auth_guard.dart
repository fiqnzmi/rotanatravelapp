import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

/// Require a logged-in user to access a subtree.
/// If not logged in, show a friendly gate with a Log In button.
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? message;

  const AuthGuard({super.key, required this.child, this.message});

  Future<bool> _isLoggedIn() => AuthService.instance.isLoggedIn();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data == true) return child;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  message ?? 'Please log in to access this section.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Log In'),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        onAuthSuccess: () {
                          // return to the guarded screen after login
                          Navigator.of(context).pop();
                        },
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
