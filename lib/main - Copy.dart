import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:askminty/menus/custom_app_bar.dart';
import 'package:askminty/menus/custom_drawer.dart';
import 'package:askminty/menus/bottom_nav_bar.dart';
import 'package:askminty/utils/webview_config.dart';
import 'package:askminty/utils/webview_channel_handler.dart';
import 'package:askminty/widgets/floating_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:askminty/data/bottom_nav_data.dart' hide CustomBottomNavigationBar;
import 'package:askminty/data/app_menu_data.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  // Ensure native OS permissions are requested for microphone.
  // This is crucial for the InAppWebView to then be able to request them from the web content.

  var microphoneStatus = await Permission.microphone.status;
  debugPrint('askminty DEBUG: Initial Microphone Permission Status: $microphoneStatus');

  await Permission.microphone.request();

  // Removed camera permission request as per your clarification
  // await Permission.camera.request(); // This line was removed

  runApp(const MyApp()); // Added const for MyApp
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASKMINTY',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF21C87A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ANDROID-ONLY TTS state
  final FlutterTts _tts = FlutterTts();
  bool _isNativeSpeaking = false;
  // REMOVED: No longer needed with simplified logic
  // bool _nativeToggleBusy = false;

  bool _isConnected = false;
  bool _isLoadingInitialData = true;
  String? _networkErrorMessage;

  InAppWebViewController? webViewController;
  double progress = 0;
  String _currentUrl = 'https://www.askminty.com/ain5/aibot.cfm';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDrawerOpen = false;
  String _coldFusionMenuState = 'home';
  int _currentBottomNavIndex = 0;
  bool _isAibotPage = false; // ADDED: New variable to track if on aibot.cfm

  late WebViewChannelHandler _channelHandler;
  List<BottomNavItem> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();

    // Android TTS lifecycle hooks
    if (Platform.isAndroid) {
      _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() {
        _isNativeSpeaking = true;
      });
      _tts.setCompletionHandler(() async {
        _isNativeSpeaking = false;
        try {
          await webViewController?.evaluateJavascript(
              source: "window.__nativeTtsEnded && window.__nativeTtsEnded();"
          );
        } catch (_) {}
      });
      _tts.setCancelHandler(() async {
        _isNativeSpeaking = false;
        try {
          await webViewController?.evaluateJavascript(
              source: "window.__nativeTtsEnded && window.__nativeTtsEnded();"
          );
        } catch (_) {}
      });
      _tts.setErrorHandler((msg) async {
        _isNativeSpeaking = false;
        try {
          await webViewController?.evaluateJavascript(
              source: "window.__nativeTtsEnded && window.__nativeTtsEnded();"
          );
        } catch (_) {}
      });
    }
    _startAppInitialization();

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _handleConnectivityChange(results.contains(ConnectivityResult.none));
    });
  }

  void _handleConnectivityChange(bool isDisconnected) {
    if (mounted) {
      setState(() {
        _isConnected = !isDisconnected;
        if (isDisconnected) {
          _networkErrorMessage = 'No internet connection. Web content may not load.';
        } else {
          _networkErrorMessage = null;
          if (!_isLoadingInitialData && webViewController != null) {
            webViewController!.reload();
          }
        }
      });
      _loadDynamicMenuData();
    }
  }

  Future<void> _startAppInitialization() async {
    setState(() {
      _isLoadingInitialData = true;
      _networkErrorMessage = null;
    });

    try {
      await _loadDynamicMenuData();
      debugPrint("Main: Dynamic menu data load attempt completed.");

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (mounted) {
        setState(() {
          _isConnected = !connectivityResult.contains(ConnectivityResult.none);
          if (!_isConnected) {
            _networkErrorMessage = 'No internet connection. The web content will not load.';
          } else {
            _networkErrorMessage = null;
          }
        });
        debugPrint("Main: Initial webview connectivity check completed. Connected: $_isConnected");
      }

    } catch (e) {
      debugPrint("Main: FATAL ERROR during initial app loading: $e");
      setState(() {
        _networkErrorMessage = "A critical error occurred during app startup.";
      });
    } finally {
      setState(() {
        _isLoadingInitialData = false;
      });
    }
  }

  Future<void> _loadDynamicMenuData() async {
    try {
      final loadedBottomNavItems = await BottomNavDataLoader.getBottomNavItemsForContext(_coldFusionMenuState);
      if (mounted) {
        setState(() {
          _bottomNavItems = loadedBottomNavItems;
          _updateBottomNavIndex(_currentUrl);
        });
        debugPrint("Main: Loaded ${_bottomNavItems.length} bottom nav items for state: $_coldFusionMenuState.");
      }

      await AppMenuDataLoader.loadMenuData(forceRefresh: true);
      debugPrint("Main: Dynamic drawer menu data loading triggered.");

    } catch (e) {
      debugPrint("Main: Error loading dynamic menu data (caught in main): $e");
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  // MODIFIED: Updated this method to set _isAibotPage
  void _loadUrlInWebView(String url) {
    if (webViewController != null && _isConnected) {
      // --- IMPORTANT: Stop current loading to ensure resource release before new load ---
      webViewController!.stopLoading();
      // --- END IMPORTANT ---
      webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      setState(() {
        _currentUrl = url;
        _isAibotPage = url.contains('aibot.cfm'); // ADDED: Check for aibot.cfm
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot load page: No internet connection.')),
      );
    }
  }

  void _updateBottomNavIndex(String url) {
    int newIndex = 0;
    if (_bottomNavItems.isNotEmpty) {
      for (int i = 0; i < _bottomNavItems.length; i++) {
        if (url.startsWith(_bottomNavItems[i].url)) {
          newIndex = i;
          break;
        }
      }
    }
    if (mounted) {
      setState(() {
        _currentBottomNavIndex = newIndex;
      });
    }
    debugPrint("Main: Updated Bottom Nav Index to $_currentBottomNavIndex for URL: $url");
  }

  void _handleColdFusionMenuStateChange(String menuValue) async {
    debugPrint("Flutter: Received menu state from ColdFusion: $menuValue");
    if (mounted) {
      setState(() {
        _coldFusionMenuState = menuValue.toLowerCase();
      });
      await _loadDynamicMenuData();
    }
  }

  Future<void> _launchUrlExternal(WebUri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${uri.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: ${uri.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.of(context).size.width * 0.75;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        if (webViewController != null && await webViewController!.canGoBack()) {
          webViewController!.goBack();
        } else {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          onMenuPressed: _toggleDrawer,
          onSearchPressed: _loadUrlInWebView,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    if (_isLoadingInitialData)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      )
                    else if (_networkErrorMessage != null && !_isConnected)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              _networkErrorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _startAppInitialization,
                              child: const Text('Retry App Startup'),
                            ),
                          ],
                        ),
                      )
                    else
                      InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                        initialSettings: InAppWebViewSettings( // --- IMPORTANT: Added InAppWebViewSettings ---
                          disableInputAccessoryView: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          iframeAllow: "microphone", // Set microphone permission for iframes
                          javaScriptEnabled: true, // Ensured JavaScript is enabled
                          // User agent is set later in onWebViewCreated, which is fine.
                        ), // --- END IMPORTANT ---
                        onPermissionRequest: (controller, request) async {
                          print('Permission request from webview: ${request.resources}');
                          // Grant specific permissions, ensure only microphone if that's all you need.
                          final allowedResources = request.resources.where((resource) {
                            return resource == PermissionResourceType.MICROPHONE;
                          }).toList();
                          return PermissionResponse(
                            resources: allowedResources,
                            action: allowedResources.isNotEmpty ? PermissionResponseAction.GRANT : PermissionResponseAction.DENY,
                          );
                        },
                        initialOptions: getWebViewOptions(), // Your custom options from webview_config.dart
                        onWebViewCreated: (controller) {
                          controller.setSettings( // This applies settings not covered by initialSettings or overrides them
                            settings: InAppWebViewSettings(
                              userAgent: getWebViewOptions().crossPlatform.userAgent,
                              disableInputAccessoryView: true,
                              // If you want to ensure iframeAllow is also set here for redundancy, you can.
                              // iframeAllow: "microphone",
                            ),
                          );
                          webViewController = controller;

                          // ANDROID-ONLY native TTS bridge handlers
                          if (Platform.isAndroid) {
                            // REMOVED: The `nativeToggle` handler was removed as it caused conflicts.
                            // The JS side already handles the toggle logic correctly.

                            // MODIFIED: Simplified `nativeSpeak` handler to only speak.
                            // The JS is now responsible for handling the toggle logic.
                            controller.addJavaScriptHandler(
                              handlerName: 'nativeSpeak',
                              callback: (args) async {
                                final text = (args.isNotEmpty ? (args[0] as String) : '');
                                final lang = (args.length > 1 ? (args[1] as String) : 'en-US');
                                final voiceName = (args.length > 2 ? (args[2] as String) : '');

                                debugPrint('nativeSpeak handler received: starting to speak');
                                try {
                                  await _tts.setLanguage(lang);
                                  await _tts.setSpeechRate(0.55);
                                  await _tts.setPitch(1.0);
                                  if (voiceName.isNotEmpty) {
                                    try { await _tts.setVoice({"name": voiceName, "locale": lang}); } catch (_) {}
                                  }
                                  if (text.trim().isNotEmpty) {
                                    await _tts.speak(text);
                                  }
                                } catch (e) {
                                  debugPrint('nativeSpeak error: $e');
                                }
                                return true;
                              },
                            );

                            // MODIFIED: Simplified `nativeStop` handler to only stop.
                            controller.addJavaScriptHandler(
                              handlerName: 'nativeStop',
                              callback: (args) async {
                                debugPrint('nativeStop handler received: stopping');
                                try {
                                  await _tts.stop();
                                } finally {
                                  _isNativeSpeaking = false;
                                  // The TTS completion/cancel handlers will call __nativeTtsEnded()
                                }
                                return true;
                              },
                            );
                          }
                          _channelHandler = WebViewChannelHandler(
                            controller: controller,
                            onMenuChanged: _handleColdFusionMenuStateChange,
                          );
                          // --- NEW: Register JavaScript handler for mic stopped event ---
                          controller.addJavaScriptHandler(
                            handlerName: 'recordingStopped', // Must match the name in JS
                            callback: (args) async {
                              debugPrint('Flutter: JavaScript handler "recordingStopped" called.');
                              if (webViewController != null) {
                                await webViewController!.pause();
                                await Future.delayed(const Duration(milliseconds: 100)); // Small delay
                                await webViewController!.resume();
                                debugPrint('Flutter: WebView pause/resume attempt complete.');
                              }
                            },
                          );
                          // --- END NEW ---
                          controller.addJavaScriptHandler( // Existing handler
                            handlerName: 'UserAgentLogger',
                            callback: (args) {
                              debugPrint("WebView JS: navigator.userAgent is: ${args[0]}");
                            },
                          );
                        },
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          final uri = navigationAction.request.url;

                          if (uri != null) {
                            if (!navigationAction.isForMainFrame && (uri.scheme == 'http' || uri.scheme == 'https')) {
                              debugPrint("Intercepted target='_blank' link in shouldOverrideUrlLoading: ${uri.toString()}");
                              _launchUrlExternal(uri);
                              return NavigationActionPolicy.CANCEL;
                            }
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                        onDownloadStartRequest: (controller, url) async {
                          debugPrint("Intercepted download request: ${url.url.toString()}");
                          _launchUrlExternal(url.url);
                        },
                        onProgressChanged: (controller, newProgress) {
                          setState(() {
                            progress = newProgress / 100;
                          });
                        },
                        onUpdateVisitedHistory: (controller, url, androidIs) async {
                          if (url != null) {
                            bool canGoBackStatus = false;
                            if (webViewController != null) {
                              canGoBackStatus = await webViewController!.canGoBack();
                            }
                            bool canGoForwardStatus = false;
                            if (webViewController != null) {
                              canGoForwardStatus = await webViewController!.canGoForward();
                            }
                            setState(() {
                              _currentUrl = url.toString();
                              _canGoBack = canGoBackStatus;
                              _canGoForward = canGoForwardStatus;
                              _isAibotPage = url.toString().contains('aibot.cfm'); // ADDED: Check for aibot.cfm
                            });
                            _updateBottomNavIndex(url.toString());
                          }
                        },
                        onLoadStop: (controller, url) async {
                          final String? userAgentFromJs = await controller.evaluateJavascript(source: "navigator.userAgent");
                          if (userAgentFromJs != null) {
                            debugPrint("WebView JS (returned): navigator.userAgent is: $userAgentFromJs");
                          } else {
                            debugPrint("WebView JS (returned): Could not get navigator.userAgent.");
                          }
                          if (_isConnected && _networkErrorMessage != null) {
                            setState(() {
                              _networkErrorMessage = null;
                            });
                          }
                        },
                        onLoadError: (controller, url, code, message) {
                          debugPrint("Error loading $url: $code, $message");

                          // Ignore NSURL -999 (request cancelled)
                          if (code == -999) {
                            debugPrint("Request was cancelled (NSURL -999). No action needed.");
                            return;
                          }


                          if (code == -2 || code == -1009 || code == -1004) {
                            setState(() {
                              _networkErrorMessage = "Page failed to load: No internet connection.";
                            });
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error loading page: $message")),
                              );
                            }
                          }
                        },
                      ),
                    if (!_isLoadingInitialData && progress < 1.0 && _networkErrorMessage == null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.8),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                    if (_isDrawerOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleDrawer,
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _isDrawerOpen ? 0 : -drawerWidth,
                      top: 0,
                      bottom: 0,
                      width: drawerWidth,
                      child: CustomDrawerPanel(
                        onUrlSelected: _loadUrlInWebView,
                        onClose: _toggleDrawer,
                        coldFusionMenuState: _coldFusionMenuState,
                      ),
                    ),
                    Positioned(
                      right: 16.0,
                      bottom: 16.0,
                      child: FloatingBackButton(
                        onPressed: () {
                          if (webViewController != null && _canGoBack) {
                            webViewController!.goBack();
                          }
                        },
                        isVisible: _canGoBack && !_isAibotPage, // MODIFIED: Added !isAibotPage check
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          onItemSelected: _loadUrlInWebView,
          currentIndex: _currentBottomNavIndex,
          coldFusionMenuState: _coldFusionMenuState,
        ),
      ),
    );
  }

  @override
  void dispose() {
    webViewController?.dispose(); // Crucially dispose the controller
    super.dispose();
  }
}
