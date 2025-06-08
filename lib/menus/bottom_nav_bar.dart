// lib/menus/bottom_nav_bar.dart
import 'package:flutter/material.dart';

/// Represents a single item in the bottom navigation bar.
class BottomNavItem {
  final String title;
  final IconData icon;
  final String url; // URL to load when this item is tapped

  BottomNavItem({
    required this.title,
    required this.icon,
    required this.url,
  });
}

/// A custom BottomNavigationBar for the application.
/// It displays a list of predefined navigation options and provides a callback
/// when an item is tapped, indicating which URL should be loaded.
class CustomBottomNavigationBar extends StatefulWidget {
  final ValueChanged<String> onItemSelected;
  final int currentIndex;
  final String coldFusionMenuState; // NEW: State passed from main.dart ('home' or 'tools')

  const CustomBottomNavigationBar({
    super.key,
    required this.onItemSelected,
    this.currentIndex = 0,
    required this.coldFusionMenuState, // NEW: Required parameter
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  // Define the static core navigation items (excluding the first dynamic one)
  static final List<BottomNavItem> _fixedNavItems = [
    BottomNavItem(title: 'Paths', icon: Icons.alt_route, url: 'https://www.finasana.com/medi/pages/e_gridv2.cfm?scope=Trilhas&sct=0&catid=0'),
    BottomNavItem(title: 'Articles', icon: Icons.article, url: 'https://www.finasana.com/medi/pages/e_gridv2.cfm?scope=Blog&sct=0&catid=0'),
    BottomNavItem(title: 'Trivia', icon: Icons.question_mark, url: 'https://www.finasana.com/medi/pages/e_gridv2.cfm?scope=Questionarios&sct=0&catid=0'),
    BottomNavItem(title: 'Podcast', icon: Icons.podcasts, url: 'https://www.finasana.com/medi/pages/e_podcast.cfm'),
    BottomNavItem(title: 'Tools', icon: Icons.build, url: 'https://www.finasana.com/medi/pages/E_loja.cfm?tools'),
  ];

  // This getter dynamically constructs the full list of items including the first one.
  List<BottomNavItem> get _allNavItems {
    final List<BottomNavItem> items = List.from(_fixedNavItems); // Create a mutable copy

    // Determine the first item based on the coldFusionMenuState
    if (widget.coldFusionMenuState == 'tools') {
      items.insert(0, BottomNavItem(title: 'Sign Out', icon: Icons.logout, url: 'https://www.finasana.com/medi/login/log_logout.cfm'));
    } else { // Default to 'home' or any other state
      items.insert(0, BottomNavItem(title: 'Sign In', icon: Icons.login, url: 'https://www.finasana.com/medi/login/log_mobi_signin.cfm'));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Ensures all labels are always visible
      currentIndex: _selectedIndex, // Use the provided currentIndex
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        final selectedUrl = _allNavItems[index].url;
        widget.onItemSelected(selectedUrl);
      },
      items: _allNavItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.title,
        );
      }).toList(),
      backgroundColor: Colors.black, // Changed to black
      selectedItemColor: Color(0xFF21C87A), // Active item color
      unselectedItemColor: Colors.white, // Inactive item color
    );
  }
}
