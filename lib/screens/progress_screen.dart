import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/download_task.dart';

/// ProgressScreen shows real-time download progress for all active tasks.
/// Supports individual progress bars, batch item counters, and cancel buttons.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTasks = context.watch<AppProvider>().activeTasks;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (activeTasks.isNotEmpty)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('History'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF2442)),
            ),
        ],
      ),
      body: activeTasks.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeTasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(context, activeTasks[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('No Active Downloads', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Start a download from the Home screen.', style: TextStyle(color: Colors.white30, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DownloadTask task) {
    final statusColor = _getStatusColor(task.status);
    final statusText = _getStatusText(task.status);
    final progressPercent = (task.progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Task Header ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    task.isBatch ? Icons.people_alt_rounded : Icons.video_file_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.isBatch)
                        Text(
                          'Item ${task.currentItem} of ${task.totalItems}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Cancel button only for active downloads
                if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.pending)
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                    onPressed: () => context.read<AppProvider>().cancelTask(task.id),
                    tooltip: 'Cancel Download',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Progress Bar ---
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: task.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withOpacity(0.7), statusColor],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- Status Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '$progressPercent%',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),

            // --- Error Message ---
            if (task.errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending: return 'Pending...';
      case DownloadStatus.downloading: return 'Downloading...';
      case DownloadStatus.completed: return 'Completed';
      case DownloadStatus.failed: return 'Failed';
      case DownloadStatus.cancelled: return 'Cancelled';
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending: return Colors.orange;
      case DownloadStatus.downloading: return Colors.blueAccent;
      case DownloadStatus.completed: return Colors.greenAccent;
      case DownloadStatus.failed: return Colors.red;
      case DownloadStatus.cancelled: return Colors.grey;
    }
  }
}
