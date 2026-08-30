import 'package:flutter/material.dart';
import 'citizen_dashboard.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'weather_screen.dart';
import 'profile_screen.dart';
import '../common/session_actions.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const CitizenDashboard(),

      SosScreen(
        onCancel: _goHome,
      ),

      const LocationScreen(),
      const WeatherScreen(),
      const ProfileScreen(),
    ];
  }

  void _goHome() {
    if (!mounted) return;

    setState(() {
      currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit =
            await SessionActions.confirmExit(context);

        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: pages[currentIndex],

        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,

          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.sos),
              label: "SOS",
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on),
              label: "Location",
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud),
              label: "Weather",
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}