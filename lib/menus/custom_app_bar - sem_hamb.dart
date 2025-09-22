import 'package:flutter/material.dart';

/// Custom AppBar that now shows only the centered logo.
/// It keeps the old constructor parameters so existing calls compile,
/// but it ignores them (no hamburger, no search).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;               // kept for backward compatibility
  final ValueChanged<String>? onSearchPressed;     // kept for backward compatibility

  const CustomAppBar({
    super.key,
    this.onMenuPressed,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // your green
      foregroundColor: Colors.black,
      centerTitle: true,
      elevation: 2,
      automaticallyImplyLeading: false, // no hamburger
      title: Image.asset(
        'assets/AskMinty_v4.png',   // update to your actual logo path
        height: kToolbarHeight * 0.7,
        fit: BoxFit.contain,
      ),
      // No leading, no actions → just the logo
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

