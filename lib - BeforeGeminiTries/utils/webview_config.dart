// lib/utils/webview_config.dart
import 'dart:io'; // Required for Platform.isIOS and Platform.isAndroid
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Required for InAppWebViewGroupOptions

/// Configures the InAppWebView with platform-specific settings,
/// including a custom User Agent.
InAppWebViewGroupOptions getWebViewOptions() {
  String baseUserAgent; // This will hold the platform-specific standard-like UA
  String customAppIdentifier = "FinayApp/1.0"; // Your specific app identifier

  // Determine a base User Agent that resembles a standard browser's UA for the platform.
  // Note: Setting userAgent in InAppWebViewOptions *replaces* the default,
  // it does not append. We are constructing a full string here.
  if (Platform.isIOS) {
    // A common iOS Safari User Agent pattern
    baseUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/ Mobile/ Safari/";
  } else if (Platform.isAndroid) {
    // A common Android Chrome User Agent pattern
    baseUserAgent = "Mozilla/5.0 (Linux; Android) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/ Mobile Safari/537.36";
  } else {
    // Fallback for other platforms (e.g., web, desktop) - less critical for mobile apps
    baseUserAgent = "Mozilla/5.0 (Unknown Platform) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/ Safari/537.36";
  }

  // Concatenate the base User Agent with your custom app identifier
  String finalUserAgent = "$baseUserAgent $customAppIdentifier";

  debugPrint("FinasanaApp: Custom User Agent set to: $finalUserAgent");

  // Return the InAppWebViewGroupOptions with the constructed User Agent
  return InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      javaScriptEnabled: true,
      useOnDownloadStart: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      userAgent: finalUserAgent, // This will be the full custom User-Agent string
      mediaPlaybackRequiresUserGesture: false,
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