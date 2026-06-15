import 'package:flutter/material.dart';
import '../services/xhs_downloader_service.dart';
import '../services/cookie_service.dart';
import '../models/download_task.dart';
import '../utils/helpers.dart';

/// AppProvider manages the global application state using the Provider pattern.
/// It bridges the UI layer with the download service and cookie service.
class AppProvider with ChangeNotifier {
  final XHSDownloaderService _downloaderService = XHSDownloaderService();
  final CookieService _cookieService = CookieService();

  bool _isCookieLoaded = false;
  bool get isCookieLoaded => _isCookieLoaded;

  final List<DownloadTask> _activeTasks = [];
  List<DownloadTask> get activeTasks => List.unmodifiable(_activeTasks);

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _isCookieLoaded = await _cookieService.hasCookie();
    notifyListeners();
  }

  // ============================================================
  // COOKIE MANAGEMENT
  // ============================================================

  /// Loads a cookie from the file at [cookiePath] and persists it.
  Future<void> loadCookie(String cookiePath) async {
    await _cookieService.saveCookieFromFile(cookiePath);
    _isCookieLoaded = true;
    notifyListeners();
  }

  /// Clears the stored cookie.
  Future<void> clearCookie() async {
    await _cookieService.clearCookie();
    _isCookieLoaded = false;
    notifyListeners();
  }

  // ============================================================
  // DOWNLOAD MANAGEMENT
  // ============================================================

  /// Starts a single video download for the given [url].
  Future<void> startSingleDownload(String url) async {
    // Validate URL
    if (!Helpers.isValidXHSLink(url)) {
      throw Exception('Invalid XHS URL: $url');
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: 'Single Download',
      status: DownloadStatus.downloading,
      isBatch: false,
    );
    _activeTasks.add(task);
    notifyListeners();

    try {
      await _downloaderService.downloadSingle(url, (progress, status) {
        task.progress = progress;
        task.status = status;
        notifyListeners();
      });
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = _formatError(e.toString());
      notifyListeners();
    }
  }

  /// Starts a profile batch download for the given [profileUrl].
  Future<void> startProfileDownload(String profileUrl) async {
    if (!Helpers.isValidXHSLink(profileUrl)) {
      throw Exception('Invalid XHS profile URL: $profileUrl');
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: profileUrl,
      title: 'Profile Batch Download',
      status: DownloadStatus.downloading,
      isBatch: true,
    );
    _activeTasks.add(task);
    notifyListeners();

    try {
      await _downloaderService.downloadProfile(
        profileUrl,
        (progress, status, currentItem, totalItems) {
          task.progress = progress;
          task.status = status;
          task.currentItem = currentItem;
          task.totalItems = totalItems;
          // Update title with item count once known
          if (totalItems > 0 && task.title == 'Profile Batch Download') {
            task.title = 'Profile: $totalItems videos found';
          }
          notifyListeners();
        },
      );
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = _formatError(e.toString());
      notifyListeners();
    }
  }

  /// Cancels the download task with the given [id].
  void cancelTask(String id) {
    final index = _activeTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _activeTasks[index].status = DownloadStatus.cancelled;
      _downloaderService.cancelDownload(id);
      notifyListeners();
    }
  }

  /// Removes completed, failed, or cancelled tasks from the active list.
  void clearFinishedTasks() {
    _activeTasks.removeWhere((t) =>
        t.status == DownloadStatus.completed ||
        t.status == DownloadStatus.failed ||
        t.status == DownloadStatus.cancelled);
    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Formats raw exception messages into user-friendly Bengali + English text.
  String _formatError(String raw) {
    if (raw.contains('Cookie is required')) {
      return 'Cookie প্রয়োজন। Settings-এ গিয়ে cookies.txt আপলোড করুন।\n(Cookie required. Please upload cookies.txt in Settings.)';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক চেক করুন।\n(No internet connection. Please check your network.)';
    }
    if (raw.contains('No downloadable media')) {
      return 'এই পোস্টে কোনো ডাউনলোডযোগ্য মিডিয়া পাওয়া যায়নি।\n(No downloadable media found in this post.)';
    }
    if (raw.contains('Could not extract')) {
      return 'লিংক থেকে পোস্ট আইডি বের করা যায়নি। সঠিক লিংক দিন।\n(Could not extract post ID. Please use a valid link.)';
    }
    return raw;
  }
}
