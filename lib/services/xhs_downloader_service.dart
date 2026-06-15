import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/download_task.dart';
import 'cookie_service.dart';
import 'notification_service.dart';
import '../utils/helpers.dart';

/// XHSDownloaderService is the core engine of the app.
/// It handles:
///   - Resolving short links (xhslink.com) to full URLs
///   - Scraping a user's profile page to collect all video/note post IDs
///   - Fetching the watermark-free video stream URL from each post
///   - Downloading files using Dio with real-time progress callbacks
///   - Cancellation support via Dio CancelToken
class XHSDownloaderService {
  final Dio _dio = Dio();
  final CookieService _cookieService = CookieService();
  final Map<String, CancelToken> _cancelTokens = {};

  // --- Realistic Browser-Like Headers to Avoid Detection ---
  static const Map<String, String> _baseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
  };

  XHSDownloaderService() {
    _dio.options.headers = _baseHeaders;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 5;
  }

  // ============================================================
  // SINGLE VIDEO DOWNLOAD
  // ============================================================

  /// Downloads a single XHS video or image note from [url].
  /// Calls [onProgress] with (progress 0.0-1.0, DownloadStatus) updates.
  Future<void> downloadSingle(
    String url,
    Function(double, DownloadStatus) onProgress,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    try {
      onProgress(0.05, DownloadStatus.downloading);

      // Step 1: Inject cookie
      await _injectCookie();

      // Step 2: Resolve short link if needed
      final resolvedUrl = await _resolveShortLink(url);
      onProgress(0.1, DownloadStatus.downloading);

      // Step 3: Extract post ID from URL
      final postId = Helpers.extractPostId(resolvedUrl);
      if (postId == null) throw Exception('Could not extract post ID from URL.');

      // Step 4: Fetch post data and extract media URL
      final mediaInfo = await _fetchPostMediaInfo(postId, cancelToken);
      onProgress(0.2, DownloadStatus.downloading);

      final mediaUrl = mediaInfo['videoUrl'] ?? mediaInfo['imageUrl'];
      final title = mediaInfo['title'] ?? 'XHS_${postId}';

      if (mediaUrl == null || mediaUrl.isEmpty) {
        throw Exception('No downloadable media found in this post.');
      }

      // Step 5: Download the file
      final savePath = await Helpers.getDownloadPath(
        Helpers.sanitizeFilename(title),
        isVideo: mediaInfo['videoUrl'] != null,
      );

      await _dio.download(
        mediaUrl,
        savePath,
        cancelToken: cancelToken,
        options: Options(headers: {
          'Referer': 'https://www.xiaohongshu.com/',
          ..._baseHeaders,
        }),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(0.2 + (received / total) * 0.8, DownloadStatus.downloading);
          }
        },
      );

      onProgress(1.0, DownloadStatus.completed);
      _saveToHistory(title, savePath);
      await NotificationService().showNotification(
        id: taskId.hashCode,
        title: 'Download Complete ✓',
        body: '"$title" has been saved.',
      );
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        onProgress(0.0, DownloadStatus.cancelled);
      } else {
        onProgress(0.0, DownloadStatus.failed);
        rethrow;
      }
    } finally {
      _cancelTokens.remove(taskId);
    }
  }

  // ============================================================
  // PROFILE BATCH DOWNLOAD
  // ============================================================

  /// Scrapes a user's profile from [profileUrl] and downloads all their videos.
  /// Calls [onProgress] with (progress, status, currentItem, totalItems) updates.
  Future<void> downloadProfile(
    String profileUrl,
    Function(double, DownloadStatus, int, int) onProgress,
  ) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    try {
      onProgress(0.0, DownloadStatus.downloading, 0, 0);

      // Step 1: Require cookie for profile scraping
      final cookie = await _cookieService.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception('Cookie is required for profile batch download. Please upload cookies.txt in Settings.');
      }
      _dio.options.headers['Cookie'] = cookie;

      // Step 2: Resolve short link
      final resolvedUrl = await _resolveShortLink(profileUrl);
      onProgress(0.02, DownloadStatus.downloading, 0, 0);

      // Step 3: Extract user ID from profile URL
      final userId = Helpers.extractUserId(resolvedUrl);
      if (userId == null) throw Exception('Could not extract user ID from profile URL.');

      // Step 4: Scrape all post IDs from the profile
      final postIds = await _scrapeProfilePostIds(userId, cancelToken);
      if (postIds.isEmpty) throw Exception('No posts found on this profile.');

      final totalItems = postIds.length;
      onProgress(0.05, DownloadStatus.downloading, 0, totalItems);

      // Step 5: Download each post
      final settings = Hive.box('settings');
      final delaySeconds = settings.get('delay', defaultValue: 1) as int;

      for (int i = 0; i < postIds.length; i++) {
        if (cancelToken.isCancelled) break;

        final currentItem = i + 1;
        onProgress(0.0, DownloadStatus.downloading, currentItem, totalItems);

        try {
          final postId = postIds[i];
          final mediaInfo = await _fetchPostMediaInfo(postId, cancelToken);
          final mediaUrl = mediaInfo['videoUrl'] ?? mediaInfo['imageUrl'];
          final title = mediaInfo['title'] ?? 'XHS_${postId}';

          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            final savePath = await Helpers.getDownloadPath(
              Helpers.sanitizeFilename(title),
              folder: userId,
              isVideo: mediaInfo['videoUrl'] != null,
            );

            await _dio.download(
              mediaUrl,
              savePath,
              cancelToken: cancelToken,
              options: Options(headers: {
                'Referer': 'https://www.xiaohongshu.com/',
                ..._baseHeaders,
              }),
              onReceiveProgress: (received, total) {
                if (total > 0) {
                  onProgress(received / total, DownloadStatus.downloading, currentItem, totalItems);
                }
              },
            );

            _saveToHistory(title, savePath);
          }
        } catch (postError) {
          // Log individual post errors but continue with the rest
          _logError('Failed to download post ${postIds[i]}: $postError');
        }

        // Delay between downloads to avoid rate limiting
        if (i < postIds.length - 1 && delaySeconds > 0) {
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }

      if (!cancelToken.isCancelled) {
        onProgress(1.0, DownloadStatus.completed, totalItems, totalItems);
        await NotificationService().showNotification(
          id: taskId.hashCode,
          title: 'Batch Download Complete ✓',
          body: 'Downloaded $totalItems items from profile.',
        );
      }
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        onProgress(0.0, DownloadStatus.cancelled, 0, 0);
      } else {
        onProgress(0.0, DownloadStatus.failed, 0, 0);
        rethrow;
      }
    } finally {
      _cancelTokens.remove(taskId);
    }
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  /// Injects the stored cookie into the Dio headers.
  Future<void> _injectCookie() async {
    final cookie = await _cookieService.getCookie();
    if (cookie != null && cookie.isNotEmpty) {
      _dio.options.headers['Cookie'] = cookie;
    }
  }

  /// Resolves a short link (xhslink.com) to its final destination URL.
  /// If the URL is already a full URL, it is returned as-is.
  Future<String> _resolveShortLink(String url) async {
    if (!url.contains('xhslink.com')) return url;

    try {
      // Follow redirects to get the final URL
      final response = await _dio.get(
        url,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final location = response.headers.value('location');
      if (location != null) return location;
    } catch (e) {
      // If redirect fails, try to extract from the response body
    }
    return url;
  }

  /// Fetches post metadata from the XHS API.
  /// Returns a map containing 'videoUrl', 'imageUrl', and 'title'.
  ///
  /// NOTE: XHS does not have a public API. This method uses the web page
  /// HTML parsing approach to extract the embedded JSON data (window.__INITIAL_STATE__).
  /// This is the most reliable method for extracting media without a watermark.
  Future<Map<String, String?>> _fetchPostMediaInfo(String postId, CancelToken cancelToken) async {
    final pageUrl = 'https://www.xiaohongshu.com/explore/$postId';

    try {
      final response = await _dio.get(
        pageUrl,
        cancelToken: cancelToken,
        options: Options(headers: {
          'Referer': 'https://www.xiaohongshu.com/',
          ..._baseHeaders,
        }),
      );

      final html = response.data.toString();

      // Extract the embedded JSON state from the HTML
      // XHS embeds data in: window.__INITIAL_STATE__={...}
      final stateMatch = RegExp(r'window\.__INITIAL_STATE__\s*=\s*(\{.*?\});', dotAll: true).firstMatch(html);

      String? videoUrl;
      String? imageUrl;
      String? title;

      if (stateMatch != null) {
        final jsonStr = stateMatch.group(1) ?? '';

        // Extract video URL (no-watermark stream)
        // XHS stores the original video URL in "originVideoKey" or "masterUrl"
        final videoMatch = RegExp(r'"masterUrl"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
        if (videoMatch != null) {
          videoUrl = videoMatch.group(1)?.replaceAll(r'\u002F', '/');
        }

        // Fallback: try h264 URL
        if (videoUrl == null) {
          final h264Match = RegExp(r'"h264"\s*:\s*\[.*?"url"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
          if (h264Match != null) {
            videoUrl = h264Match.group(1)?.replaceAll(r'\u002F', '/');
          }
        }

        // Extract image URL for image notes
        if (videoUrl == null) {
          final imgMatch = RegExp(r'"urlDefault"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
          if (imgMatch != null) {
            imageUrl = imgMatch.group(1)?.replaceAll(r'\u002F', '/');
          }
        }

        // Extract title
        final titleMatch = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
        if (titleMatch != null) {
          title = titleMatch.group(1);
        }
      }

      // Fallback: try meta tags for title
      if (title == null) {
        final metaTitle = RegExp(r'<meta\s+name="description"\s+content="([^"]+)"').firstMatch(html);
        title = metaTitle?.group(1) ?? 'XHS_$postId';
      }

      return {
        'videoUrl': videoUrl,
        'imageUrl': imageUrl,
        'title': title,
      };
    } catch (e) {
      throw Exception('Failed to fetch post info for $postId: $e');
    }
  }

  /// Scrapes all post IDs from a user's profile page.
  /// Uses the XHS user notes API endpoint with cursor-based pagination.
  Future<List<String>> _scrapeProfilePostIds(String userId, CancelToken cancelToken) async {
    final List<String> postIds = [];
    String? cursor;
    bool hasMore = true;

    while (hasMore) {
      if (cancelToken.isCancelled) break;

      try {
        // XHS user notes API endpoint
        final apiUrl = 'https://www.xiaohongshu.com/user/profile/$userId';
        final params = {
          'cursor': cursor ?? '',
          'user_id': userId,
          'image_formats': 'jpg,webp,avif',
        };

        final response = await _dio.get(
          apiUrl,
          queryParameters: params,
          cancelToken: cancelToken,
          options: Options(headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': 'https://www.xiaohongshu.com/user/profile/$userId',
            ..._baseHeaders,
          }),
        );

        final html = response.data.toString();

        // Extract post IDs from the HTML using regex
        // XHS note links follow the pattern: /explore/{noteId}
        final noteMatches = RegExp(r'/explore/([a-f0-9]{24})').allMatches(html);
        for (final match in noteMatches) {
          final id = match.group(1);
          if (id != null && !postIds.contains(id)) {
            postIds.add(id);
          }
        }

        // Check for pagination cursor
        final cursorMatch = RegExp(r'"cursor"\s*:\s*"([^"]+)"').firstMatch(html);
        cursor = cursorMatch?.group(1);
        hasMore = cursor != null && cursor.isNotEmpty;

        // Safety limit to prevent infinite loops
        if (postIds.length >= 500) hasMore = false;

        // Small delay between pagination requests
        if (hasMore) await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        hasMore = false;
        if (postIds.isEmpty) {
          throw Exception('Failed to scrape profile: $e');
        }
      }
    }

    return postIds;
  }

  /// Saves a completed download entry to the Hive history box.
  void _saveToHistory(String title, String path) {
    try {
      final box = Hive.box('history');
      box.add({
        'title': title,
        'path': path,
        'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      });
    } catch (e) {
      _logError('Failed to save history: $e');
    }
  }

  /// Logs error messages to the Hive log box for the log screen.
  void _logError(String message) {
    try {
      final box = Hive.box('settings');
      final logs = (box.get('logs', defaultValue: <String>[]) as List).cast<String>();
      logs.insert(0, '[${DateTime.now()}] $message');
      if (logs.length > 200) logs.removeLast();
      box.put('logs', logs);
    } catch (_) {}
  }

  /// Cancels a download task by its [id].
  void cancelDownload(String id) {
    if (_cancelTokens.containsKey(id)) {
      _cancelTokens[id]?.cancel('User cancelled');
      _cancelTokens.remove(id);
    }
  }
}
