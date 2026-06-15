import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService manages local push notifications for download events.
/// Uses the flutter_local_notifications package.
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the notification plugin. Must be called before any notifications are shown.
  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap (e.g., navigate to history screen)
      },
    );

    // Create the notification channel for Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'xhs_downloader_channel',
      'XHS Downloads',
      description: 'Notifications for XHS Downloader progress and completion.',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Shows a standard notification with [title] and [body].
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'xhs_downloader_channel',
      'XHS Downloads',
      channelDescription: 'Notifications for XHS Downloader progress and completion.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details);
  }

  /// Shows a progress notification for ongoing downloads.
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required int progress,
    required int maxProgress,
  }) async {
    if (!_initialized) await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'xhs_downloader_channel',
      'XHS Downloads',
      channelDescription: 'Notifications for XHS Downloader progress and completion.',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      onlyAlertOnce: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, '$progress / $maxProgress items', details);
  }

  /// Cancels a notification by [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
