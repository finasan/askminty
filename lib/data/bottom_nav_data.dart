// lib/data/bottom_nav_data.dart
import 'dart:convert'; // For jsonDecode
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:flutter/material.dart'; // For IconData
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http; // For making HTTP requests

/// Represents a single item in the bottom navigation bar.
class BottomNavItem {
  final String title;
  final IconData icon; // IconData is required for bottom nav bar
  final String url; // URL to load when this item is tapped

  BottomNavItem({
    required this.title,
    required this.icon,
    required this.url,
  });

  // Factory constructor to create a BottomNavItem from a JSON map
  factory BottomNavItem.fromJson(Map<String, dynamic> json) {
    // Map string icon name to Flutter IconData, similar to AppMenuItem
    IconData iconData;
    switch (json['icon']) {

      case 'login': iconData = Icons.login; break;
      case 'new': iconData = Icons.open_in_new_sharp; break;
      case 'help': iconData = Icons.live_help; break;
      case 'chat': iconData = Icons.chat; break;
      case 'about': iconData = Icons.info_rounded; break;
      case 'logout': iconData = Icons.logout; break;
      case 'alt_route': iconData = Icons.alt_route; break; // For Paths icon
      case 'article': iconData = Icons.article; break; // For Articles icon
      case 'question_mark': iconData = Icons.question_mark; break; // For Trivia icon
      case 'podcasts': iconData = Icons.podcasts; break; // For Podcasts icon
      case 'search': iconData = Icons.search; break; // For Search icon
      case 'shopping_cart_outlined': iconData = Icons.shopping_cart_outlined; break; // For Loja icon
      case 'build': iconData = Icons.build; break; // For Tools icon
      case 'home_outlined': iconData = Icons.home_outlined; break;
      case 'insert_chart_outlined': iconData = Icons.insert_chart_outlined; break;
      case 'person_outline': iconData = Icons.person_outline; break;
      default: iconData = Icons.help_outline; // Default icon if not found
    }

    return BottomNavItem(
      title: json['title'],
      icon: iconData,
      url: json['url'],
    );
  }
}

/// A static class to load and manage bottom navigation data.
class BottomNavDataLoader {
  static const String _remoteUrl = 'https://www.askminty.com/parms/jsonbottom_ai.cfm';
  static const String _fallbackAssetPath = 'assets/bottom_nav_data.json';
  static Map<String, List<BottomNavItem>>? _bottomNavDataCache;

  /// Loads bottom navigation data from a remote URL or a local asset.
  static Future<Map<String, List<BottomNavItem>>> loadBottomNavData() async {
    if (_bottomNavDataCache != null) {
      return _bottomNavDataCache!;
    }

    String? jsonString;
    try {
      final response = await http.get(Uri.parse(_remoteUrl));
      if (response.statusCode == 200) {
        jsonString = response.body;
        debugPrint("BottomNavDataLoader: Successfully loaded JSON from remote URL. Length: ${jsonString.length}");
      } else {
        debugPrint("BottomNavDataLoader: Failed to load JSON from remote URL (Status: ${response.statusCode}). Falling back to assets.");
      }
    } catch (e) {
      debugPrint("BottomNavDataLoader: ERROR loading from remote URL: $e. Falling back to assets.");
    }

    // If remote loading fails or is empty, try loading from local assets
    if (jsonString == null || jsonString.isEmpty) {
      try {
        jsonString = await rootBundle.loadString(_fallbackAssetPath);
        debugPrint("BottomNavDataLoader: Successfully loaded JSON from assets. Length: ${jsonString.length}");
      } catch (e) {
        debugPrint("BottomNavDataLoader: ERROR loading from fallback asset $_fallbackAssetPath: $e");
        return {}; // Return empty map if fallback also fails
      }
    }

    // Parse the loaded JSON string (either from external or fallback)
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString!);
      _bottomNavDataCache = {};
      jsonMap.forEach((key, value) {
        _bottomNavDataCache![key] = (value as List)
            .map((itemJson) => BottomNavItem.fromJson(itemJson))
            .toList();
      });
      debugPrint("BottomNavDataLoader: Successfully parsed bottom nav data. Keys: ${_bottomNavDataCache?.keys}");
      return _bottomNavDataCache!;
    } catch (e) {
      debugPrint("BottomNavDataLoader: ERROR parsing JSON data: $e"); // This would catch errors from asset JSON too
      return {}; // Return empty map on parsing error
    }
  }

  /// Retrieves bottom navigation items for a specific context (e.g., 'home' or 'tools').
  static Future<List<BottomNavItem>> getBottomNavItemsForContext(String context) async {
    final allBottomNavData = await loadBottomNavData();
    final List<BottomNavItem> items = allBottomNavData[context] ?? [];
    debugPrint("BottomNavDataLoader: Retrieving bottom nav items for context '$context': ${items.length} items found.");
    return items;
  }
}