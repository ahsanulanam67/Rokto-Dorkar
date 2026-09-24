import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'donors_screen.dart';
import 'management_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';
import '../services/auth_state.dart';

import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final canModerate = context.watch<AuthState>().canModerate;
    final screens = <Widget>[
      const DonorsScreen(),
      const RequestsScreen(),
      const ProfileScreen(),
      if (canModerate) const ManagementScreen(),
      const AboutScreen(),
    ];
    final titles = <String>[
      'Find donors',
      'Blood requests',
      'My profile',
      if (canModerate) 'Management',
      'About',
    ];
    if (_index >= screens.length) _index = 0;
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final navigation = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.bloodtype_rounded, size: 42),
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('Donors'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.emergency_outlined),
          label: Text('Requests'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Profile'),
        ),
        if (canModerate)
          const NavigationRailDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: Text('Manage'),
          ),
        const NavigationRailDestination(
          icon: Icon(Icons.info_outline),
          label: Text('About'),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Row(
        children: [
          if (wide) navigation,
          Expanded(
            child: IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Donors',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.emergency_outlined),
                  label: 'Requests',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
                if (canModerate)
                  const NavigationDestination(
                    icon: Icon(Icons.admin_panel_settings_outlined),
                    label: 'Manage',
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: 'About',
                ),
              ],
            ),
    );
  }
}
