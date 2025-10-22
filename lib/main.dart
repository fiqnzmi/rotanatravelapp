import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/packages_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'splash_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const RotanaApp());
}

class RotanaApp extends StatelessWidget {
  const RotanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rotana Travel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(), // <- splash will route to RootShell (dashboard)
    );
  }
}

/// App shell with bottom navigation (Home / Packages / Trips / Inbox / Profile)
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _pages = const <Widget>[
    HomeScreen(),
    PackagesScreen(),
    TripsScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Packages',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}