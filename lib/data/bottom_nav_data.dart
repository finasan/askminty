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
      case 'logout': iconData = Icons.logout; break;
      case 'alt_route': iconData = Icons.alt_route; break; // For Paths icon
      case 'article': iconData = Icons.article; break; // For Articles icon
      case 'question_mark': iconData = Icons.question_mark; break; // For Trivia icon
      case 'podcasts': iconData = Icons.podcasts; break; // For Podcast icon
      case 'build': iconData = Icons.build; break; // For Tools icon
    // Add more cases here if you have other icons in your JSON
      default: iconData = Icons.error; // Default to an error icon if not found
    }

    return BottomNavItem(
      title: json['title'] as String,
      icon: iconData,
      url: json['url'] as String,
    );
  }
}

/// A class to load and provide bottom navigation bar data.
class BottomNavDataLoader {
  static Map<String, List<BottomNavItem>>? _bottomNavDataCache;
  static const String _externalBottomNavUrl = 'https://www.finasana.com/jsonbottom.cfm';
  static const String _fallbackAssetPath = 'assets/bottom_nav_data.json';

  /// Loads bottom navigation data from the external source or falls back to assets.
  /// Caches the data to avoid reloading on subsequent calls.
  static Future<Map<String, List<BottomNavItem>>> loadBottomNavData() async {
    if (_bottomNavDataCache != null) {
      debugPrint("BottomNavDataLoader: Returning bottom nav data from cache.");
      return _bottomNavDataCache!;
    }

    String? jsonString;
    bool externalLoadSuccessful = false;

    try {
      debugPrint("BottomNavDataLoader: Attempting to load bottom nav data from external URL: $_externalBottomNavUrl");
      final response = await http.get(Uri.parse(_externalBottomNavUrl));

      if (response.statusCode == 200) {
        try {
          // Attempt to decode the response body to ensure it's valid JSON
          jsonDecode(response.body); // Just try decoding, don't store yet
          jsonString = response.body; // If decode succeeds, then assign
          externalLoadSuccessful = true;
          debugPrint("BottomNavDataLoader: Successfully loaded and preliminarily validated JSON from external URL. Length: ${jsonString.length}");
        } on FormatException catch (e) {
          debugPrint("BottomNavDataLoader: External URL returned non-JSON content (Status: ${response.statusCode}). JSON parsing failed: $e. Falling back to assets.");
          externalLoadSuccessful = false; // Explicitly set to false due to bad JSON
        }
      } else {
        debugPrint("BottomNavDataLoader: Failed to load from external URL (Status: ${response.statusCode}). Falling back to assets.");
        externalLoadSuccessful = false;
      }
    } catch (e) {
      debugPrint("BottomNavDataLoader: Error fetching from external URL: $e. Falling back to assets.");
      externalLoadSuccessful = false;
    }

    // If external load failed or was not attempted (or returned bad JSON), load from assets
    if (!externalLoadSuccessful || jsonString == null || jsonString.isEmpty) {
      try {
        debugPrint("BottomNavDataLoader: Loading bottom nav data from assets: $_fallbackAssetPath");
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
      debugPrint("BottomNavDataLoader: ERROR parsing JSON data: $e");
      return {}; // Return empty map on parsing error
    }
  }

  /// Retrieves bottom navigation items for a specific context (e.g., 'home' or 'tools').
  static Future<List<BottomNavItem>> getBottomNavItemsForContext(String context) async {
    final allBottomNavData = await loadBottomNavData();
    final List<BottomNavItem> items = allBottomNavData[context] ?? [];
    debugPrint("BottomNavDataLoader: Retrieving bottom nav items for context '$context'. Found ${items.length} items.");
    return items;
  }
}