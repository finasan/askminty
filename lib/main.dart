import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:finay/menus/custom_app_bar.dart';
import 'package:finay/menus/custom_drawer.dart';
import 'package:finay/menus/bottom_nav_bar.dart';
import 'package:finay/utils/webview_config.dart';
import 'package:finay/utils/webview_channel_handler.dart';
import 'package:finay/widgets/floating_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
// import 'package:permission_handler/permission.dart'; // Temporarily commented out
import 'package:finay/data/bottom_nav_data.dart' hide CustomBottomNavigationBar;
import 'package:finay/data/app_menu_data.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  // Future<void> _requestMicrophonePermission() async { // Temporarily commented out
  //   var status = await Permission.microphone.status; // Temporarily commented out
  //   if (!status.isGranted) { // Temporarily commented out
  //     await Permission.microphone.request(); // Temporarily commented out
  //   } // Temporarily commented out
  // } // Temporarily commented out

  // await _requestMicrophonePermission(); // Temporarily commented out

  runApp(MyApp());
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
  bool _isConnected = false;
  bool _isLoadingInitialData = true;
  String? _networkErrorMessage;

  InAppWebViewController? webViewController;
  double progress = 0;
  String _currentUrl = 'https://www.finasana.com';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDrawerOpen = false;
  String _coldFusionMenuState = 'home';
  int _currentBottomNavIndex = 0;

  late WebViewChannelHandler _channelHandler;
  List<BottomNavItem> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();
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

  void _loadUrlInWebView(String url) {
    if (webViewController != null && _isConnected) {
      webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      setState(() {
        _currentUrl = url;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot load page: No internet connection.')),
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
                            Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              _networkErrorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _startAppInitialization,
                              child: Text('Retry App Startup'),
                            ),
                          ],
                        ),
                      )
                    else
                      InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                        initialSettings: InAppWebViewSettings(
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
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
                            _updateBottomNavIndex(url.toString());
                          }
                        },
                        onLoadStop: (controller, url) async {
                          debugPrint("WebView JS (returned): Could not get navigator.userAgent.");
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
      ),
    );
  }
}