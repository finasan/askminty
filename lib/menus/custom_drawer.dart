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
    _loadMenuItems();
  }

  @override
  void didUpdateWidget(covariant CustomDrawerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload menu items if the coldFusionMenuState changes
    if (widget.coldFusionMenuState != oldWidget.coldFusionMenuState) {
      debugPrint("CustomDrawerPanel: coldFusionMenuState changed from ${oldWidget.coldFusionMenuState} to ${widget.coldFusionMenuState}. Reloading menu.");
      _loadMenuItems();
    }
  }

  /// Loads menu items based on the current coldFusionMenuState.
  Future<void> _loadMenuItems() async {
    debugPrint("CustomDrawerPanel: Attempting to load menu items for state: ${widget.coldFusionMenuState}");
    final List<AppMenuItem> items = await AppMenuData.getMenuItemsForContext(widget.coldFusionMenuState);
    if (mounted) {
      setState(() {
        _currentMenuItems = items;
        debugPrint("CustomDrawerPanel: Loaded ${items.length} items for state: ${widget.coldFusionMenuState}");
      });
    }
  }

  /// Recursively builds menu tiles, handling nested children.
  List<Widget> _buildMenuItemTiles(List<AppMenuItem> items, {double currentIndent = 0}) {
    // This value is the standard horizontal offset for a ListTile's title
    // when a leading icon is present (default contentPadding + leading icon area).
    // This should align the children's text with the parent's text.
    const double textAlignmentOffset = 38.0;

    return items.map((item) {
      if (item.children != null && item.children!.isNotEmpty) {
        // If the item has children, create an ExpansionTile
        return Padding(
          padding: EdgeInsets.only(left: currentIndent), // Apply current indentation for this level
          child: ExpansionTile(
            leading: item.icon != null ? Icon(item.icon) : null,
            title: Text(item.title),
            // For children, increase the indent by `textAlignmentOffset`
            // to align their content with the parent's title text.
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
                widget.onUrlSelected(item.url!); // Use the callback to load URL in parent's webview
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
          ..._buildMenuItemTiles(_currentMenuItems), // Build menu tiles starting with no indent
        ],
      ),
    );
  }
}