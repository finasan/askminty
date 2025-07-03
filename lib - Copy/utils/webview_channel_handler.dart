// lib/utils/webview_channel_handler.dart
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert'; // Still used, but now for a more robust check

/// A typedef for the callback function that will receive menu updates.
typedef OnMenuChangedCallback = void Function(String menuValue);

/// Manages JavaScript channel communication from the WebView to Flutter.
class WebViewChannelHandler {
  final InAppWebViewController controller;
  final OnMenuChangedCallback onMenuChanged;

  WebViewChannelHandler({
    required this.controller,
    required this.onMenuChanged,
  }) {
    _addMyChannelHandler();
  }

  /// Registers the 'MyChannel' JavaScript handler to receive messages from the WebView.
  void _addMyChannelHandler() {
    controller.addJavaScriptHandler(
      handlerName: 'MyChannel', // The name of the JavaScript channel
      callback: (args) {
        // Expected format: args = ['Home:quiet'] or ['Tools:quiet']
        // It could also potentially be ['{"currentMenu": "Home"}'] if ColdFusion changes its format.
        debugPrint('Received message from WebView (MyChannel): $args');

        if (args.isNotEmpty) {
          String rawMessage = args[0].toString(); // Ensure it's a string

          // Try to parse as JSON first (for robustness in case format changes)
          try {
            final Map<String, dynamic> data = jsonDecode(rawMessage);
            if (data.containsKey('currentMenu') && data['currentMenu'] is String) {
              final String menuValue = data['currentMenu'];
              debugPrint('Parsed JSON currentMenu: $menuValue');
              onMenuChanged(menuValue); // Pass the menu value to the Flutter app
              return; // Exit if successfully parsed as JSON
            }
          } catch (e) {
            debugPrint('Not a JSON message, attempting plain string parse. Error: $e');
            // Continue to plain string parsing if JSON parsing fails
          }

          // If not JSON, assume plain string format like "Home:quiet" or "Tools:quiet"
          if (rawMessage.contains(':')) {
            final String menuValue = rawMessage.split(':')[0].trim(); // Get "Home" or "Tools"
            debugPrint('Parsed plain string menuValue: $menuValue');
            onMenuChanged(menuValue); // Pass the menu value to the Flutter app
          } else {
            debugPrint('Unrecognized MyChannel message format: $rawMessage');
          }
        }
      },
    );
  }

  /// Optional: Remove the handler if needed (e.g., when the WebView is disposed).
  void dispose() {
    controller.removeJavaScriptHandler(handlerName: 'MyChannel');
  }
}

// Ensure your ColdFusion JavaScript sends:
// window.flutter_inappwebview.callHandler('MyChannel', 'Home:quiet');
// or
// window.flutter_inappwebview.callHandler('MyChannel', 'Tools:quiet');
