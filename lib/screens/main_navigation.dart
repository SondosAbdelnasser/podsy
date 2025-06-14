import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/category_detection_service.dart';
import 'podcast_home.dart';
import 'search_screen.dart';
import 'likes_screen.dart';
import 'users_list_page.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/expanded_player_modal.dart';
import '../services/audio_player_service.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final CategoryDetectionService _categoryService = CategoryDetectionService();
  
  final List<Widget> _screens = [
    Home(),
    SearchScreen(),
    LikesScreen(),
    UsersListPage(),
  ];

  Future<void> _testWitAiToken() async {
    final result = await _categoryService.testWitAiToken();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? 'Token is valid!' : 'Token validation failed. Check console for details.'),
        backgroundColor: result ? Colors.green : Colors.red,
      ),
    );
  }

  void _showExpandedPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpandedPlayerModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main content of the current screen
          _screens[_currentIndex],

          // Mini Player Bar
          if (audioPlayerService.currentEpisode != null) // Only show if an episode is loaded
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiniPlayerBar(onExpand: _showExpandedPlayer),
                  // This SizedBox is to make space for the bottom navigation bar
                  // It should have the same height as your BottomNavigationBar
                  SizedBox(height: kBottomNavigationBarHeight), 
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Likes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
} 