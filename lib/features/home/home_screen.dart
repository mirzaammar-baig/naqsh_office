import 'package:flutter/material.dart';
import 'package:naqsh_office/features/dashboard/dashboard_screen.dart';
import 'package:naqsh_office/features/members/members_screen.dart';
import 'package:naqsh_office/features/payments/payments_screen.dart';
import 'package:naqsh_office/features/plots/plots_screen.dart';
import 'package:naqsh_office/features/home/app_drawer.dart';
import 'package:naqsh_office/features/auth/auth_repository.dart';
import 'package:naqsh_office/features/plots/blocks_screen.dart';
import 'package:naqsh_office/features/plots/plot_form_screen.dart';
import 'package:naqsh_office/features/members/member_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthRepository authRepository = AuthRepository();
  int selectedIndex = 0;

  static const List<String> titles = [
    'Dashboard',
    'Plots',
    'Members',
    'Payments',
  ];

  static const List<Widget> pages = [
    DashboardScreen(),
    PlotsScreen(),
    MembersScreen(),
    PaymentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          if (selectedIndex == 1)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlocksScreen()),
                );
              },
              icon: const Icon(Icons.view_module_outlined, size: 20),
              label: const Text('Blocks'),
            ),
          if (selectedIndex == 1)
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlotFormScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Plot'),
            ),
          if (selectedIndex == 2)
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemberFormScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Member'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(userEmail: authRepository.currentUser?.email ?? ''),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Plots',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}