/// Represents the current status of a download task.
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

/// DownloadTask holds all state for a single download operation.
/// A task can represent either a single video download or a batch profile download.
class DownloadTask {
  /// Unique identifier for this task (timestamp-based).
  final String id;

  /// The original URL provided by the user.
  final String url;

  /// Human-readable title for display in the UI.
  String title;

  /// Download progress as a fraction from 0.0 to 1.0.
  double progress;

  /// Current status of the task.
  DownloadStatus status;

  /// Error message if the task failed.
  String? errorMessage;

  /// Whether this is a batch (profile) download.
  final bool isBatch;

  /// For batch downloads: the index of the item currently being downloaded.
  int currentItem;

  /// For batch downloads: the total number of items to download.
  int totalItems;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    this.errorMessage,
    this.isBatch = false,
    this.currentItem = 0,
    this.totalItems = 0,
  });

  /// Returns a display-friendly percentage string.
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';

  /// Returns true if the task is still running.
  bool get isActive =>
      status == DownloadStatus.pending || status == DownloadStatus.downloading;

  /// Returns true if the task has finished (success or failure).
  bool get isFinished =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;
}
