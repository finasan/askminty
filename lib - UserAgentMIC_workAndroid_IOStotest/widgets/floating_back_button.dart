// lib/widgets/floating_back_button.dart
import 'package:flutter/material.dart';

/// A customizable floating action button for back navigation.
///
/// It can be made visible/invisible based on the `isVisible` property,
/// and its `onPressed` callback is triggered when the button is tapped.
class FloatingBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVisible;

  const FloatingBackButton({
    super.key,
    required this.onPressed,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use AnimatedOpacity for a smooth fade-in/out effect
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      // Use Visibility to control whether the widget takes up space
      // when not visible, ensuring it doesn't block taps on content behind it.
      child: Visibility(
        visible: isVisible,
        child: FloatingActionButton(
          onPressed: isVisible ? onPressed : null, // Disable if not visible
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          mini: true, // Make it a smaller FloatingActionButton
          child: const Icon(Icons.arrow_back), // Back arrow icon
        ),
      ),
    );
  }
}