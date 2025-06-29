import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:finay/menus/custom_app_bar.dart';
import 'package:finay/menus/custom_drawer.dart';
import 'package:finay/menus/bottom_nav_bar.dart'; // Correct import for CustomBottomNavigationBar
import 'package:finay/utils/webview_config.dart';
import 'package:finay/utils/webview_channel_handler.dart';
import 'package:finay/widgets/floating_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:finay/data/bottom_nav_data.dart' hide CustomBottomNavigationBar; // Import for BottomNavItem and loader, hide conflicting export
import 'package:flutter_sound/flutter_sound.dart'; // Add this import for FlutterSoundRecorder
import 'package:path_provider/path_provider.dart'; // Add this import for getTemporaryDirectory

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  await _requestMicrophonePermission();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key}); // Correct placement of the MyApp constructor

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // These are commented out as they were causing issues without full implementation
  // and seem to be part of an incomplete feature based on the original problem.
  // If you intend to use audio recording, you'll need to fully implement
  // the FlutterSound package.
  // final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  // String? _filePath;
  // bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // _initRecorder(); // Commented out
  }

  // Future<void> _initRecorder() async {
  //   final dir = await getTemporaryDirectory();
  //   _filePath = '${dir.path}/voice.aac';
  //   await _recorder.openRecorder();
  // }

  // Future<void> startNativeRecording() async {
  //   if (!_recorder.isRecording) {
  //     await _recorder.startRecorder(toFile: _filePath!);
  //     setState(() {
  //       _isRecording = true;
  //     });
  //   }
  // }

  // Future<void> stopNativeRecording() async {
  //   if (_recorder.isRecording) {
  //     await _recorder.stopRecorder();
  //     await _recorder.closeRecorder();
  //     setState(() {
  //       _isRecording = false;
  //     });
  //     print("Recording saved to: $_filePath");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TEMPL',
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
  bool _hasLoadError = false;

  InAppWebViewController? webViewController;
  double progress = 0;
  String _currentUrl = 'https://www.finasana.com'; // Initial URL
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDrawerOpen = false;
  String _coldFusionMenuState = 'home'; // Initial state based on ColdFusion context
  int _currentBottomNavIndex = 0;

  late WebViewChannelHandler _channelHandler;
  List<BottomNavItem> _bottomNavItems = []; // To store dynamically loaded bottom nav items

  bool _isWebViewReady = false;

  Future<void> _initializeWebView() async {
    try {
      final result = await InternetAddress.lookup('www.finasana.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        setState(() {
          _isWebViewReady = true;
        });
        return;
      }
    } catch (_) {}

    // Retry once after short delay
    await Future.delayed(Duration(seconds: 2));
    try {
      final result = await InternetAddress.lookup('www.finasana.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        setState(() {
          _isWebViewReady = true;
        });
      }
    } catch (e) {
      print("DNS resolution failed again: $e");
    }
  }

  @override
  void initState() {
    _initializeWebView();
    super.initState();
    _loadInitialBottomNavItems(); // Load bottom nav items based on initial state
  }

  // --- NEW: Load bottom navigation items dynamically ---
  Future<void> _loadInitialBottomNavItems() async {
    final loadedItems = await BottomNavDataLoader.getBottomNavItemsForContext(_coldFusionMenuState);
    if (mounted) {
      setState(() {
        _bottomNavItems = loadedItems;
        _updateBottomNavIndex(_currentUrl); // Update index based on current URL and newly loaded items
      });
      debugPrint("Main: Loaded ${_bottomNavItems.length} bottom nav items for state: $_coldFusionMenuState");
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _loadUrlInWebView(String url) {
    if (webViewController != null) {
      webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      setState(() {
        _currentUrl = url;
        // _updateBottomNavIndex is now called in onUpdateVisitedHistory and from _loadInitialBottomNavItems
        // no direct call needed here, as onUpdateVisitedHistory will trigger
      });
    }
  }

  // --- MODIFIED: Dynamic _updateBottomNavIndex based on loaded items ---
  void _updateBottomNavIndex(String url) {
    int newIndex = 0; // Default to the first item if no match
    for (int i = 0; i < _bottomNavItems.length; i++) {
      // Use startsWith for more robust URL matching, as the actual WebView URL
      // might contain query parameters or fragments not present in the base URL from JSON.
      // Adjust matching logic if your URLs require a different comparison (e.g., exact match, regex).
      if (url.startsWith(_bottomNavItems[i].url)) {
        newIndex = i;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _currentBottomNavIndex = newIndex;
      });
    }
    debugPrint("Main: Updated Bottom Nav Index to $_currentBottomNavIndex for URL: $url");
  }

  // --- MODIFIED: Handle ColdFusion menu state changes and reload bottom nav items ---
  void _handleColdFusionMenuStateChange(String menuValue) async {
    debugPrint("Flutter: Received menu state from ColdFusion: $menuValue");
    if (mounted) {
      setState(() {
        _coldFusionMenuState = menuValue.toLowerCase();
      });
      // Reload bottom nav items specific to the new ColdFusion state
      await _loadInitialBottomNavItems(); // This will also trigger _updateBottomNavIndex
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

    // --- NEW: PopScope to handle physical back button ---
    return PopScope(
      canPop: false, // Prevent immediate pop
      onPopInvoked: (didPop) async {
        if (didPop) {
          return; // If system already handled back, do nothing
        }
        if (webViewController != null && await webViewController!.canGoBack()) {
          webViewController!.goBack();
          // No need to call setState here, onUpdateVisitedHistory will handle canGoBack/Forward updates
        } else {
          // If WebView cannot go back, allow the app to be popped/closed
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
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                      initialSettings: InAppWebViewSettings(
                        mediaPlaybackRequiresUserGesture: false, // 👈 this is the key setting for mic/camera
                        allowsInlineMediaPlayback: true,         // iOS video/audio autoplay
                      ),
                      androidOnPermissionRequest: (controller, origin, resources) async {
                        return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT,
                        );
                      },
                      initialOptions: getWebViewOptions(),
                      onWebViewCreated: (controller) {
                        controller.setSettings(
                          settings: InAppWebViewSettings(
                            userAgent: getWebViewOptions().crossPlatform.userAgent,
                          ),
                        );
                        webViewController = controller;
                        _channelHandler = WebViewChannelHandler(
                          controller: controller,
                          onMenuChanged: _handleColdFusionMenuStateChange,
                        );
                        controller.addJavaScriptHandler(
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
                      // --- MODIFIED: Ensure bottom nav index is updated here ---
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
                          });
                          _updateBottomNavIndex(url.toString()); // Update bottom nav index on history change
                        }


                      },



                      // >>> CORREÇÃO: Removendo a verificação getJavaScriptHandler <<<
                      onLoadStop: (controller, url) async {
                        debugPrint("WebView JS (returned): Could not get navigator.userAgent.");
                        final String? userAgentFromJs = await controller.evaluateJavascript(source: "navigator.userAgent");
                        if (userAgentFromJs != null) {
                          debugPrint("WebView JS (returned): navigator.userAgent is: $userAgentFromJs");
                        } else {
                          debugPrint("WebView JS (returned): Could not get navigator.userAgent.");
                        }
                      },
                      // <<< FIM DA CORREÇÃO >>>

                      onLoadError: (controller, url, code, message) {
                        debugPrint("Error loading $url: $code, $message");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error loading page: $message")),
                        );
                      },






                    ),
                    if (progress < 1.0)
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
                    if (_isDrawerOpen) // Only show the GestureDetector when the drawer is open
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleDrawer, // Call _toggleDrawer to close the drawer
                          child: Container(
                            color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
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
                        isVisible: _canGoBack,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // --- PASS currentBottomNavIndex DIRECTLY ---
        bottomNavigationBar: CustomBottomNavigationBar(
          onItemSelected: _loadUrlInWebView,
          currentIndex: _currentBottomNavIndex,
          coldFusionMenuState: _coldFusionMenuState,
        ),
      ),
    );
  }
}