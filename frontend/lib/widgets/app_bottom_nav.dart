import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Jadwal',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: 'Pengingat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFFFE2CC),
      destinations: destinations,
    );
  }
}
