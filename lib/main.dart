import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:finay/menus/custom_app_bar.dart';
import 'package:finay/menus/custom_drawer.dart'; // Ensure this points to CustomDrawerPanel
import 'package:finay/menus/bottom_nav_bar.dart';
import 'package:finay/utils/webview_config.dart';
import 'package:finay/utils/webview_channel_handler.dart';
import 'package:finay/widgets/floating_back_button.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'dart:io'; // <-- ADDED THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ADDED THIS PLATFORM CHECK:
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

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

  @override
  void initState() {
    super.initState();
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
        _updateBottomNavIndex(url);
      });
    }
  }

  void _updateBottomNavIndex(String url) {
    if (url.contains('log_mobi_signin.cfm') || url.contains('log_logout.cfm')) {
      _currentBottomNavIndex = 0;
    } else if (url.contains('e_paths.cfm')) {
      _currentBottomNavIndex = 1;
    } else if (url.contains('idv2.cfm')) {
      _currentBottomNavIndex = 2;
    } else if (url.contains('e_search.cfm')) {
      _currentBottomNavIndex = 3;
    } else if (url.contains('e_loja.cfm')) {
      _currentBottomNavIndex = 4;
    } else {
      _currentBottomNavIndex = 0;
    }
  }

  void _handleColdFusionMenuStateChange(String menuValue) {
    debugPrint("Flutter: Received menu state from ColdFusion: $menuValue");
    setState(() {
      _coldFusionMenuState = menuValue.toLowerCase();
    });
  }

  // Function to launch URLs externally
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

    return Scaffold(
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
                    // Handle navigation requests
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final uri = navigationAction.request.url;

                      if (uri != null) {
                        // Check if it's a navigation intended for a new window (often target="_blank")
                        // This typically means navigationAction.isForMainFrame is false
                        // and it's an HTTP/HTTPS scheme.
                        if (!navigationAction.isForMainFrame && (uri.scheme == 'http' || uri.scheme == 'https')) {
                          debugPrint("Intercepted target='_blank' link in shouldOverrideUrlLoading: ${uri.toString()}");
                          _launchUrlExternal(uri);
                          return NavigationActionPolicy.CANCEL; // Prevent WebView from loading it
                        }
                      }
                      return NavigationActionPolicy.ALLOW; // Allow other navigations
                    },
                    // NEW: Handle download requests (including PDFs)
                    onDownloadStartRequest: (controller, url) async {
                      debugPrint("Intercepted download request: ${url.url.toString()}");
                      _launchUrlExternal(url.url); // Use url_launcher for downloads
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
                          _updateBottomNavIndex(url.toString());
                        });
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
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: _loadUrlInWebView,
        currentIndex: _currentBottomNavIndex,
        coldFusionMenuState: _coldFusionMenuState,
      ),
    );
  }
}