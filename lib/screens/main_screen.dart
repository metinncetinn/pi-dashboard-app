import 'package:flutter/material.dart';
import '../main.dart';
import 'settings_screen.dart';
import 'portfolio_screen.dart';
import 'weather_screen.dart';
import 'reminders_screen.dart';
import 'gallery_screen.dart';
import 'tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PortfolioScreen(),
    WeatherScreen(),
    RemindersScreen(),
    GalleryScreen(),
    ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PI / DASHBOARD',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Ayarlar
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          // Tema toggle
          IconButton(
            icon: Icon(
              PiDashboardApp.of(context)?.isDark == true
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round,
              size: 20,
            ),
            onPressed: () => PiDashboardApp.of(context)?.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Portföy',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            label: 'Hava',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Hatırlatıcı',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Galeri',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Araçlar',
          ),
        ],
      ),
    );
  }
}