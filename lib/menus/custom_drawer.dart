// lib/menus/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:finay/data/app_menu_data.dart'; // Import your menu data models and loader
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
    _loadMenuItems(forceRefresh: false);
  }

  @override
  void didUpdateWidget(covariant CustomDrawerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload items if the coldFusionMenuState changes, but do NOT force a refresh here.
    // The force refresh will now be handled only when the specific 'home' menu item is tapped.
    if (widget.coldFusionMenuState != oldWidget.coldFusionMenuState) {
      _loadMenuItems(forceRefresh: false);
    }
  }

  /// Loads menu items for the current coldFusionMenuState.
  /// `forceRefresh` bypasses the cache in AppMenuData.
  Future<void> _loadMenuItems({bool forceRefresh = false}) async {
    final items = await AppMenuData.getMenuItemsForContext(
      widget.coldFusionMenuState,
      forceRefresh: forceRefresh, // Pass the forceRefresh parameter to the data loader
    );
    if (mounted) {
      setState(() {
        _currentMenuItems = items;
      });
      debugPrint("CustomDrawerPanel: Loaded menu items for state '${widget.coldFusionMenuState}'. Count: ${items.length}");
    }
  }

  // Helper to build recursive menu tiles with indentation
  List<Widget> _buildMenuItemTiles(List<AppMenuItem> menuItems, {double currentIndent = 0.0}) {
    final double textAlignmentOffset = 56.0; // Standard offset to align text with ListTiles that have a leading icon

    return menuItems.map((item) {
      if (item.children != null && item.children!.isNotEmpty) {
        // If it has children, create an ExpansionTile
        return Padding(
          padding: EdgeInsets.only(left: currentIndent), // Apply current indentation
          child: ExpansionTile(
            leading: item.icon != null ? Icon(item.icon) : null,
            title: Text(item.title),
            // Indent children by adding to the currentIndent and then adjusting for text alignment
            children: _buildMenuItemTiles(item.children!, currentIndent: currentIndent + textAlignmentOffset),
          ),
        );
      } else {
        // If it's a leaf item (no children), create a ListTile
        return Padding(
          padding: EdgeInsets.only(left: currentIndent), // Apply current indentation for this level
          child: ListTile(
            leading: item.icon != null ? Icon(item.icon) : null,
            title: Text(item.title),
            onTap: () {
              widget.onClose(); // Close the panel before performing the action
              if (item.url != null) {
                // Load URL in parent's webview
                widget.onUrlSelected(item.url!);

                // --- MODIFIED LOGIC: Force refresh ONLY if this is the 'home' menu item with specific URL ---
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
        );
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