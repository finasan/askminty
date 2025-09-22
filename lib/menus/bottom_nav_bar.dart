// lib/menus/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:askminty/data/bottom_nav_data.dart'; // Import the new data loader

/// A custom BottomNavigationBar for the application.
/// It displays a list of dynamic navigation options and provides a callback
/// when an item is tapped, indicating which URL should be loaded.
class CustomBottomNavigationBar extends StatefulWidget {
  final ValueChanged<String> onItemSelected;
  final int currentIndex;
  final String coldFusionMenuState; // State passed from main.dart ('home' or 'tools')

  const CustomBottomNavigationBar({
    super.key,
    required this.onItemSelected,
    this.currentIndex = 0,
    required this.coldFusionMenuState,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 0;
  List<BottomNavItem> _navItems = []; // Will store the dynamically loaded items

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _loadNavItems(); // Load items when the widget initializes
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coldFusionMenuState != oldWidget.coldFusionMenuState) {
      _loadNavItems();
    }
    if (widget.currentIndex != oldWidget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  /// Asynchronously loads bottom navigation items based on the current state.
  Future<void> _loadNavItems() async {
    debugPrint("CustomBottomNavigationBar: Attempting to load bottom nav items for state: ${widget.coldFusionMenuState}");
    final loadedItems = await BottomNavDataLoader.getBottomNavItemsForContext(widget.coldFusionMenuState);
    if (mounted) {
      setState(() {
        _navItems = loadedItems;
        if (_selectedIndex >= _navItems.length) {
          _selectedIndex = 0;
        }
      });
      debugPrint("CustomBottomNavigationBar: Loaded ${_navItems.length} items for state: ${widget.coldFusionMenuState}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> displayItems = _navItems.isEmpty
        ? [
      BottomNavigationBarItem(
        icon: Icon(Icons.info),
        label: 'Loading...',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.refresh),
        label: 'Please Wait',
      ),
    ]
        : _navItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.title,
      );
    }).toList();

    // ✅ Wrapped in SizedBox with custom height
    return SizedBox(
      height: 58, // increase height (default ~56)
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_navItems.isNotEmpty && index < _navItems.length) {
            setState(() {
              _selectedIndex = index;
            });
            final selectedUrl = _navItems[index].url;
            widget.onItemSelected(selectedUrl);
          } else {
            debugPrint("CustomBottomNavigationBar: Tap ignored. Items not loaded or invalid index during loading.");
          }
        },
        items: displayItems,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        backgroundColor: const Color(0xFF21C87A),
        iconSize: 24
        , // ✅ bigger icons, better centering
      ),
    );
  }
}
