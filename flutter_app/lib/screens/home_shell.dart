import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'donors_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _screens = [
    DonorsScreen(),
    RequestsScreen(),
    ProfileScreen(),
    AboutScreen(),
  ];
  static const _titles = [
    'Find donors',
    'Blood requests',
    'My profile',
    'About',
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final navigation = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.bloodtype_rounded, size: 42),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('Donors'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.emergency_outlined),
          label: Text('Requests'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Profile'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.info_outline),
          label: Text('About'),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Row(
        children: [
          if (wide) navigation,
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Donors',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emergency_outlined),
                  label: 'Requests',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: 'About',
                ),
              ],
            ),
    );
  }
}
