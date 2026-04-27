import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'volunteers_screen.dart';
import 'resources_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation shell — 4 clean tabs
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    VolunteersScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', active: _idx == 0, onTap: () => setState(() => _idx = 0)),
                _NavItem(icon: Icons.people_rounded, label: 'Volunteers', active: _idx == 1, onTap: () => setState(() => _idx = 1)),
                _NavItem(icon: Icons.inventory_2_rounded, label: 'Resources', active: _idx == 2, onTap: () => setState(() => _idx = 2)),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', active: _idx == 3, onTap: () => setState(() => _idx = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? C.red.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: active ? C.red : C.mist),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? C.red : C.mist)),
        ]),
      ),
    );
  }
}
