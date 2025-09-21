// lib/menus/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:askminty/data/app_menu_data.dart'; // Import your menu data models and loader
import 'package:flutter/foundation.dart'; // For debugPrint

/// A custom menu panel widget for the application.
/// It displays a list of predefined menu options with associated actions or URLs.
/// This widget is designed to be used within a custom slide-in mechanism.
///
/// It is context-sensitive based on `coldFusionMenuState`.
class CustomDrawerPanel extends StatefulWidget {
  // Callback to inform the parent about the selected URL from the drawer.
  final ValueChanged<String> onUrlSelected;
  final VoidCallback onClose; // Callback to close the panel when an item is tapped
  final String coldFusionMenuState; // 'home' or 'tools' from ColdFusion

  const CustomDrawerPanel({
    super.key,
    required this.onUrlSelected,
    required this.onClose,
    required this.coldFusionMenuState,
  });

  @override
  State<CustomDrawerPanel> createState() => _CustomDrawerPanelState();
}

class _CustomDrawerPanelState extends State<CustomDrawerPanel> {
  List<AppMenuItem> _currentMenuItems = [];

  @override
  void initState() {
    super.initState();
    // Load menu items initially without forcing a refresh.
    // They will come from cache or a fresh network fetch if cache is empty.
    _loadMenuItems();
  }

  @override
  void didUpdateWidget(covariant CustomDrawerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload items if the coldFusionMenuState changes
    if (widget.coldFusionMenuState != oldWidget.coldFusionMenuState) {
      debugPrint("CustomDrawerPanel: ColdFusion menu state changed from '${oldWidget.coldFusionMenuState}' to '${widget.coldFusionMenuState}'. Reloading drawer menu items.");
      // Force refresh when the ColdFusion state changes to ensure the correct menu is loaded
      _loadMenuItems(forceRefresh: true);
    }
  }

  // --- MODIFIED: Load menu items dynamically with forceRefresh option ---
  Future<void> _loadMenuItems({bool forceRefresh = false}) async {
    debugPrint("CustomDrawerPanel: Loading menu items for context: ${widget.coldFusionMenuState} (forceRefresh: $forceRefresh)");
    final loadedItems = await AppMenuDataLoader.getMenuItemsForContext(widget.coldFusionMenuState, forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _currentMenuItems = loadedItems;
      });
      debugPrint("CustomDrawerPanel: Loaded ${_currentMenuItems.length} menu items for state: ${widget.coldFusionMenuState}");
    }
  }

  List<Widget> _buildMenuItemTiles(List<AppMenuItem> menuItems, {int indentLevel = 0}) {
    return menuItems.expand((item) {
      if (item.children != null && item.children!.isNotEmpty) {
        // Handle parent items with children
        return [
          ListTile(
            leading: item.icon != null ? Icon(item.icon) : null,
            title: Text(item.title),
            onTap: () {
              // For parent items, typically you might just expand/collapse or do nothing
              debugPrint('Parent menu item "${item.title}" tapped.');
              // If you want to allow tapping parent to also navigate, add item.url check here
            },
            // You might want an expansion tile here if you want collapsible menus
          ),
          ..._buildMenuItemTiles(item.children!, indentLevel: indentLevel + 1), // Recursively build children
        ];
      } else {
        // Handle leaf items
        return [
          Padding(
            padding: EdgeInsets.only(left: 16.0 * indentLevel), // Apply indentation
            child: ListTile(
              leading: item.icon != null ? Icon(item.icon) : null,
              title: Text(item.title),
              onTap: () async {
                widget.onClose(); // Close the drawer when an item is tapped
                if (item.url != null) {
                  debugPrint('Menu item "${item.title}" clicked, loading URL: ${item.url}');
                  widget.onUrlSelected(item.url!);

                  // --- MODIFIED LOGIC: Force refresh for "Home" menu item ---
                  // Using a more specific contains check based on the exact URL provided by the user.
                  final bool isHomeMenuItem = item.url!.toLowerCase().contains('indexm.cfm?pt=smartphone&lang=1');

                  if (isHomeMenuItem) {
                    debugPrint("CustomDrawerPanel: 'Home' menu item (indexm.cfm?pt=smartphone&lang=1) tapped. Forcing menu data refresh.");
                    // Trigger a force refresh of the menu items for the *current* coldFusionMenuState.
                    // This reloads the menu itself after navigating home.
                    _loadMenuItems(forceRefresh: true);
                  }
                  // --- END MODIFIED LOGIC ---

                } else {
                  debugPrint('${item.title} clicked (no action/URL defined)');
                }
              },
            ),
          ),
        ];
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material( // Use Material to give it elevation and background color
      color: Theme.of(context).cardColor, // Use card color for a nice background
      elevation: 8.0, // Give it a slight shadow
      child: ListView(
        padding: EdgeInsets.zero, // Remove default ListView padding
        children: <Widget>[
          // --- DrawerHeader was REMOVED to restore original look and feel ---
          ..._buildMenuItemTiles(_currentMenuItems), // Build menu tiles starting with no indent
        ],
      ),
    );
  }
}