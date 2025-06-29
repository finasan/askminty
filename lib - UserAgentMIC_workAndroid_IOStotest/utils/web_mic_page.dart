
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class WebMicPage extends StatefulWidget {
  const WebMicPage({Key? key}) : super(key: key);

  @override
  State<WebMicPage> createState() => _WebMicPageState();
}

class _WebMicPageState extends State<WebMicPage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _requestMicPermissions();
  }

  Future<void> _requestMicPermissions() async {
    if (Platform.isAndroid) {
      await Permission.microphone.request();
      await Permission.camera.request(); // In case camera is also requested
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Recorder')),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://www.finasana.com/ain/aindexmic.cfm"),
          ),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            iframeAllow: "microphone; camera",
            iframeAllowFullscreen: true,
            javaScriptEnabled: true,
          ),
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT,
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("CONSOLE: \${consoleMessage.message}");
          },
        ),
      ),
    );
  }
}
