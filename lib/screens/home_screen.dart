import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'wardrobe_screen.dart';
import 'outfits_screen.dart';
import 'calendar_screen.dart';
import 'suggestion_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    WardrobeScreen(),
    OutfitsScreen(),
    CalendarScreen(),
    SuggestionScreen(),
    ProfileScreen(),
  ];

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Wardrobe'),
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Outfits'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Suggest'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 4
          ? FloatingActionButton.small(
              onPressed: _logout,
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.logout, color: AppColors.error),
            )
          : null,
    );
  }
}
