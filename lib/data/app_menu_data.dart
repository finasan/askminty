// lib/data/app_menu_data.dart
import 'dart:convert'; // For jsonDecode
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:flutter/material.dart'; // For IconData
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http; // For making HTTP requests

/// A data model for a single menu item.
/// Can be a top-level item or a child of another item.
class AppMenuItem {
  final String title;
  final IconData? icon; // Icons are optional in JSON, map to IconData
  final String? url;
  final List<AppMenuItem>? children; // For nested menus

  AppMenuItem({
    required this.title,
    this.icon,
    this.url,
    this.children,
  });

  // Factory constructor to create an AppMenuItem from a JSON map
  factory AppMenuItem.fromJson(Map<String, dynamic> json) {
    List<AppMenuItem>? children;
    if (json['children'] != null) {
      children = (json['children'] as List)
          .map((childJson) => AppMenuItem.fromJson(childJson))
          .toList();
    }

    // Map string icon name to Flutter IconData
    // This is a simplified mapping; you might need a more comprehensive one
    // if you have many custom icons or different icon sets.
    IconData? iconData;
    if (json['icon'] != null) {
      switch (json['icon']) {
        case 'login':
          iconData = Icons.login;
          break;
        case 'account_circle':
          iconData = Icons.account_circle;
          break;
        case 'info_outline':
          iconData = Icons.info_outline;
          break;
        case 'quiz':
          iconData = Icons.quiz;
          break;
        case 'help_outline':
          iconData = Icons.help_outline;
          break;
        case 'home':
          iconData = Icons.home;
          break;
        case 'settings':
          iconData = Icons.settings;
          break;
        case 'video_library':
          iconData = Icons.video_library;
          break;
        case 'shopping_cart':
          iconData = Icons.shopping_cart;
          break;
        case 'school':
          iconData = Icons.school;
          break;
        case 'mail_outline':
          iconData = Icons.mail_outline;
          break;
        case 'alt_route':
          iconData = Icons.alt_route;
          break; // For Paths icon
        case 'article':
          iconData = Icons.article;
          break; // For Articles icon
        case 'build':
          iconData = Icons.build;
          break; // For Tools icon
        case 'logout':
          iconData = Icons.logout;
          break; // For Sign Out icon
        case 'dashboard':
          iconData = Icons.dashboard;
          break; // For Main Options icon
        default:
          iconData = null; // No icon if not mapped
      }
    }

    return AppMenuItem(
      title: json['title'] as String,
      icon: iconData,
      url: json['url'] as String?,
      children: children,
    );
  }
}

/// A class to load and provide menu data from assets.
class AppMenuData {
  static Map<String, List<AppMenuItem>>? _menuDataCache;
  static const String _externalMenuUrl = 'https://www.finasana.com/jsonmenu.cfm';
  static const String _fallbackAssetPath = 'assets/menu_data.json';

  /// Loads menu data from the external source or falls back to assets.
  /// Caches the data to avoid reloading on subsequent calls.
  static Future<Map<String, List<AppMenuItem>>> loadMenuData() async {
    if (_menuDataCache != null) {
      debugPrint("AppMenuData: Returning menu data from cache.");
      return _menuDataCache!;
    }

    String? jsonString;
    bool externalLoadSuccessful = false;

    try {
      // Attempt to load from external URL first
      debugPrint("AppMenuData: Attempting to load menu data from external URL: $_externalMenuUrl");
      final response = await http.get(Uri.parse(_externalMenuUrl));

      if (response.statusCode == 200) {
        // --- NEW: Try to parse JSON here. If it fails, treat as an unsuccessful external load ---
        try {
          // Attempt to decode the response body to ensure it's valid JSON
          jsonDecode(response.body); // Just try decoding, don't store yet
          jsonString = response.body; // If decode succeeds, then assign
          externalLoadSuccessful = true;
          debugPrint("AppMenuData: Successfully loaded and preliminarily validated JSON from external URL. Length: ${jsonString.length}");
        } on FormatException catch (e) {
          debugPrint("AppMenuData: External URL returned non-JSON content (Status: ${response.statusCode}). JSON parsing failed: $e. Falling back to assets.");
          externalLoadSuccessful = false; // Explicitly set to false due to bad JSON
        }
      } else {
        debugPrint(
            "AppMenuData: Failed to load from external URL (Status: ${response.statusCode}). Falling back to assets.");
        externalLoadSuccessful = false;
      }
    } catch (e) {
      debugPrint("AppMenuData: Error fetching from external URL: $e. Falling back to assets.");
      externalLoadSuccessful = false;
    }

    // If external load failed or was not attempted (or returned bad JSON), load from assets
    if (!externalLoadSuccessful || jsonString == null || jsonString.isEmpty) {
      try {
        debugPrint("AppMenuData: Loading menu data from assets: $_fallbackAssetPath");
        jsonString = await rootBundle.loadString(_fallbackAssetPath);
        debugPrint("AppMenuData: Successfully loaded JSON from assets. Length: ${jsonString.length}");
      } catch (e) {
        debugPrint("AppMenuData: ERROR loading from fallback asset $_fallbackAssetPath: $e");
        return {}; // Return empty map if fallback also fails
      }
    }

    // Parse the loaded JSON string (either from external or fallback)
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString!);
      _menuDataCache = {};
      jsonMap.forEach((key, value) {
        _menuDataCache![key] = (value as List)
            .map((itemJson) => AppMenuItem.fromJson(itemJson))
            .toList();
      });
      debugPrint("AppMenuData: Successfully parsed menu data. Keys: ${_menuDataCache?.keys}");
      return _menuDataCache!;
    } catch (e) {
      debugPrint("AppMenuData: ERROR parsing JSON data: $e"); // This would catch errors from asset JSON too
      return {}; // Return empty map on parsing error
    }
  }

  /// Retrieves menu items for a specific context (e.g., 'home' or 'tools').
  static Future<List<AppMenuItem>> getMenuItemsForContext(String context) async {
    final allMenuData = await loadMenuData();
    // === IMPORTANT FIX: Use the context directly as the key ===
    final List<AppMenuItem> items = allMenuData[context] ?? [];
    debugPrint("AppMenuData: Retrieving menu items for context '$context'. Found ${items.length} items.");
    return items;
  }
}