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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  @override
  void initState() {
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
                      initialOptions: getWebViewOptions(),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        _channelHandler = WebViewChannelHandler(
                          controller: controller,
                          onMenuChanged: _handleColdFusionMenuStateChange,
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
                      onLoadError: (controller, url, code, message) {
                        debugPrint("Error loading $url: $code, $message");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error loading page: ${message}")),
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
                    // >>> MODIFICATION STARTS HERE <<<
                    if (_isDrawerOpen) // Only show the GestureDetector when the drawer is open
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleDrawer, // Call _toggleDrawer to close the drawer
                          child: Container(
                            color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                          ),
                        ),
                      ),
                    // >>> MODIFICATION ENDS HERE <<<
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
