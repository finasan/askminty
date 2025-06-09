import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isIOS) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint("Unhandled error: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finasana App',
      debugShowCheckedModeBanner: false,
      home: const WebViewContainer(),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});
  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://www.finasana.com"),
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadError: (controller, url, code, message) {
            controller.loadData(
              data: "<html><body><h2>Failed to load page.</h2><p>$message</p></body></html>",
              baseUrl: WebUri("about:blank"),
              mimeType: "text/html",
              encoding: "utf-8",
            );
          },
          onLoadHttpError: (controller, url, statusCode, description) {
            controller.loadData(
              data: "<html><body><h2>HTTP Error $statusCode</h2><p>$description</p></body></html>",
              baseUrl: WebUri("about:blank"),
              mimeType: "text/html",
              encoding: "utf-8",
            );
          },
        ),
      ),
    );
  }
}
