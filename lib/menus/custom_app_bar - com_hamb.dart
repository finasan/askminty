// lib/menus/custom_app_bar.dart
import 'package:flutter/material.dart';

/// A custom AppBar for the application.
///
/// This AppBar displays a logo as its title,
/// includes a leading hamburger icon button to open the drawer,
/// and a trailing search icon button to open a specific URL.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed; // Callback for the hamburger icon
  final ValueChanged<String> onSearchPressed; // Callback for the search icon with a URL parameter


  const CustomAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onSearchPressed,

  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      title: Image.asset(
        'assets/AskMinty_v4.png', // Path to your logo image from the provided baseline
        height: kToolbarHeight * 0.7, // Adjust height as needed, e.g., 70% of AppBar height
        fit: BoxFit.contain, // Ensures the image fits within bounds without cropping
      ),
      centerTitle: true, // Centers the logo in the AppBar
      leading: IconButton(
        // MODIFIED: Always show menu icon
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed, // Always call onMenuPressed
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search), // Search icon
          onPressed: () {
            onSearchPressed('https://www.finasana.com/medi/pages/e_search.cfm?buscar');
          },
          tooltip: 'Search',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}