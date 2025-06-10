// lib/menus/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:finay/data/bottom_nav_data.dart'; // Import the new data loader

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
    // Reload items if the coldFusionMenuState changes
    if (widget.coldFusionMenuState != oldWidget.coldFusionMenuState) {
      _loadNavItems();
    }
    // Update selected index if it changes from parent (e.g., if you set it externally)
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
        // Optionally reset _selectedIndex if the list structure significantly changes
        // or ensure it's within bounds. For now, we assume current index remains valid.
        if (_selectedIndex >= _navItems.length) {
          _selectedIndex = 0; // Reset if out of bounds
        }
      });
      debugPrint("CustomBottomNavigationBar: Loaded ${_navItems.length} items for state: ${widget.coldFusionMenuState}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no items are loaded yet, provide placeholder items to satisfy BottomNavigationBar's assertion.
    // The actual items will be rendered once _navItems is populated.
    final List<BottomNavigationBarItem> displayItems = _navItems.isEmpty
        ? [
      // Placeholder items (at least two required for BottomNavigationBar)
      BottomNavigationBarItem(
        icon: Icon(Icons.info), // You can choose any placeholder icon
        label: 'Loading...',    // Placeholder label
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.refresh), // Another placeholder icon
        label: 'Please Wait',     // Another placeholder label
      ),
    ]
        : _navItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.title,
      );
    }).toList();

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Ensures all labels are always visible
      currentIndex: _selectedIndex,
      onTap: (index) {
        // Only allow tap if actual items are loaded and index is valid for those items
        if (_navItems.isNotEmpty && index < _navItems.length) {
          setState(() {
            _selectedIndex = index;
          });
          final selectedUrl = _navItems[index].url;
          widget.onItemSelected(selectedUrl);
        } else {
          // If items are not loaded yet or an invalid index is tapped (e.g., on placeholder items),
          // you can choose to do nothing, log, or show a temporary message.
          debugPrint("CustomBottomNavigationBar: Tap ignored. Items not loaded or invalid index during loading.");
        }
      },
      items: displayItems, // Use the 'displayItems' list which handles placeholders
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(context).colorScheme.surface,
      // You can add more styling here if needed
    );
  }
}