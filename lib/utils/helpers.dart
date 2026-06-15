import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Helpers provides static utility functions used across the app.
class Helpers {
  /// Requests the necessary storage permissions for Android.
  /// On Android 11+ (API 30+), requests MANAGE_EXTERNAL_STORAGE.
  /// On older versions, requests READ/WRITE_EXTERNAL_STORAGE.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 11+ requires MANAGE_EXTERNAL_STORAGE for full access
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    // Fallback for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Returns the absolute save path for a downloaded file.
  /// Files are saved to: /storage/emulated/0/XHS_Downloads/[folder]/[filename].[ext]
  static Future<String> getDownloadPath(
    String filename, {
    String? folder,
    bool isVideo = true,
  }) async {
    await requestStoragePermission();

    String basePath = '/storage/emulated/0/XHS_Downloads';
    if (folder != null && folder.isNotEmpty) {
      basePath = '$basePath/${sanitizeFilename(folder)}';
    }

    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = isVideo ? 'mp4' : 'jpg';
    // Avoid filename collisions by appending a timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$basePath/${sanitizeFilename(filename)}_$timestamp.$ext';
  }

  /// Validates whether a given URL is a valid XHS link.
  static bool isValidXHSLink(String url) {
    if (url.isEmpty) return false;
    return url.contains('xhslink.com') ||
        url.contains('xiaohongshu.com') ||
        url.contains('xhs.cn');
  }

  /// Extracts the post/note ID from an XHS URL.
  /// Handles patterns like: /explore/{24-char-hex-id}
  static String? extractPostId(String url) {
    // Standard explore URL
    final exploreMatch = RegExp(r'/explore/([a-f0-9]{24})').firstMatch(url);
    if (exploreMatch != null) return exploreMatch.group(1);

    // Discovery URL pattern
    final discoveryMatch = RegExp(r'/discovery/item/([a-f0-9]{24})').firstMatch(url);
    if (discoveryMatch != null) return discoveryMatch.group(1);

    // Short link with ID in path
    final shortMatch = RegExp(r'/([a-f0-9]{24})').firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);

    return null;
  }

  /// Extracts the user ID from an XHS profile URL.
  /// Handles patterns like: /user/profile/{userId}
  static String? extractUserId(String url) {
    final match = RegExp(r'/user/profile/([a-zA-Z0-9]+)').firstMatch(url);
    return match?.group(1);
  }

  /// Sanitizes a string to be safe for use as a filename.
  /// Removes or replaces characters that are invalid in file paths.
  static String sanitizeFilename(String name) {
    // Remove characters that are invalid in file names
    String sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    // Limit length to 100 characters
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }

    return sanitized.isEmpty ? 'xhs_download' : sanitized;
  }

  /// Formats a byte count into a human-readable string (e.g., "12.5 MB").
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
