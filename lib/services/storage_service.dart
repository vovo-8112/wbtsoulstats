import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) 'dart:io';

/// Unified storage service that works on both web and mobile platforms
class StorageService {
  static Future<void> setString(String key, String value) async {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  static Future<String?> getString(String key) async {
    if (kIsWeb) {
      return html.window.localStorage[key];
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  static Future<void> setStringList(String key, List<String> values) async {
    if (kIsWeb) {
      html.window.localStorage[key] = jsonEncode(values);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, values);
    }
  }

  static Future<List<String>?> getStringList(String key) async {
    if (kIsWeb) {
      final raw = html.window.localStorage[key];
      if (raw == null || raw.isEmpty) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return null;
      }
      return null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key);
    }
  }
}
