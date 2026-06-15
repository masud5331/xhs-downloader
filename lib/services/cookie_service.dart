import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// CookieService handles persistent storage and retrieval of the XHS session cookie.
/// The cookie is stored as a plain string in SharedPreferences.
class CookieService {
  static const String _cookieKey = 'xhs_cookie_v1';

  /// Reads a `cookies.txt` file from [path] and saves its content.
  /// Supports both Netscape format and simple key=value format.
  Future<void> saveCookieFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Cookie file not found at: $path');
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw Exception('Cookie file is empty.');
    }

    // Parse Netscape format cookies.txt into a single Cookie header string
    final cookieHeader = _parseCookiesFile(content);
    if (cookieHeader.isEmpty) {
      throw Exception('No valid cookies found in the file. Make sure it is a valid cookies.txt from Xiaohongshu.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookieHeader);
  }

  /// Parses a Netscape-format cookies.txt file and returns a Cookie header string.
  /// Only includes cookies relevant to xiaohongshu.com.
  String _parseCookiesFile(String content) {
    final lines = content.split('\n');
    final cookiePairs = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      // Skip comments and empty lines
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Netscape format: domain\tflag\tpath\tsecure\texpiry\tname\tvalue
      final parts = trimmed.split('\t');
      if (parts.length >= 7) {
        final domain = parts[0];
        final name = parts[5];
        final value = parts[6];

        // Only include cookies for xiaohongshu.com
        if (domain.contains('xiaohongshu') || domain.contains('xhslink')) {
          cookiePairs.add('$name=$value');
        }
      } else if (trimmed.contains('=')) {
        // Simple key=value format
        cookiePairs.add(trimmed);
      }
    }

    return cookiePairs.join('; ');
  }

  /// Returns the stored cookie string, or null if none is stored.
  Future<String?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  /// Returns true if a non-empty cookie is stored.
  Future<bool> hasCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_cookieKey);
    return cookie != null && cookie.isNotEmpty;
  }

  /// Removes the stored cookie.
  Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }
}
