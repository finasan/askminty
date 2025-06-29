// lib/utils/webview_config.dart
import 'dart:io'; // Required for Platform.isIOS and Platform.isAndroid
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Required for InAppWebViewGroupOptions

/// Configures the InAppWebView with platform-specific settings,
/// including a custom User Agent.
InAppWebViewGroupOptions getWebViewOptions() {
  String customUserAgent;

  // Determine base User Agent based on platform
  if (Platform.isIOS) {
    // Example iOS User Agent - Reverted to specific version
    customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1";
  } else if (Platform.isAndroid) {
    // Example Android User Agent - Reverted to specific version
    customUserAgent = "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36";
  } else {
    // Fallback for other platforms (e.g., web, desktop)
    customUserAgent = "Mozilla/5.0 (Unknown Platform) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36";
  }

  // Concatenate custom suffix
  String suffix = Platform.isAndroid
      ? " Flutter-gonative-Android" // Adjusted suffix based on context
      : " Flutter-gonative-iOS"; // Adjusted suffix based on context

  customUserAgent = "$customUserAgent $suffix";
  debugPrint("FinasanaApp: Custom User Agent set to: $customUserAgent");

  // Return the InAppWebViewGroupOptions with the custom User Agent
  return InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      javaScriptEnabled: true,
      useOnDownloadStart: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      userAgent: customUserAgent,
      mediaPlaybackRequiresUserGesture: false, // NEW: Allow media to play...
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
      mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );
}