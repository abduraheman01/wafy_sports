import 'package:flutter/material.dart';
import 'package:sports_app/screens/leaderboard_screen.dart';
import 'package:sports_app/screens/matches_page.dart';
import 'package:sports_app/screens/simple_manager_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchesPage(),
    const LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('assets/images/sports_logo.png'),
        ),
        title: const Text('Wafy Sports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "Manager Page",
            icon: Icon(Icons.settings, color: Colors.grey.shade400),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SimpleManagerPage()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade500,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Matches'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
        ],
      ),
    );
  }
}