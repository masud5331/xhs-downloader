import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

/// HomeScreen is the main entry point of the app.
/// It provides a large text field for pasting XHS links and two prominent action buttons.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Pulsing animation for the main logo/icon
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Validates the URL, requests permissions, and starts a single video download.
  Future<void> _handleSingleDownload() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) {
      _showError('Please paste a valid XHS link first.\nঅনুগ্রহ করে একটি বৈধ লিংক পেস্ট করুন।');
      return;
    }
    if (!Helpers.isValidXHSLink(url)) {
      _showError('Invalid link format. Please use an xhslink.com or xiaohongshu.com URL.\nঅবৈধ লিংক ফরম্যাট।');
      return;
    }

    final hasPermission = await Helpers.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) _showError('Storage permission is required to save downloads.\nডাউনলোড সেভ করতে স্টোরেজ অনুমতি প্রয়োজন।');
      return;
    }

    if (mounted) {
      context.read<AppProvider>().startSingleDownload(url);
      Navigator.pushNamed(context, '/progress');
    }
  }

  /// Validates the URL, requests permissions, and starts a full profile batch download.
  Future<void> _handleProfileDownload() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) {
      _showError('Please paste a valid XHS profile link first.\nঅনুগ্রহ করে একটি বৈধ প্রোফাইল লিংক পেস্ট করুন।');
      return;
    }
    if (!Helpers.isValidXHSLink(url)) {
      _showError('Invalid link format. Please use an xhslink.com or xiaohongshu.com URL.\nঅবৈধ লিংক ফরম্যাট।');
      return;
    }

    final isCookieLoaded = context.read<AppProvider>().isCookieLoaded;
    if (!isCookieLoaded) {
      _showCookieWarning();
      return;
    }

    final hasPermission = await Helpers.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) _showError('Storage permission is required.\nস্টোরেজ অনুমতি প্রয়োজন।');
      return;
    }

    if (mounted) {
      context.read<AppProvider>().startProfileDownload(url);
      Navigator.pushNamed(context, '/progress');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCookieWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cookie Required', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Profile batch download requires a valid cookie.\n\nPlease go to Settings and upload your cookies.txt file.\n\nপ্রোফাইল ডাউনলোডের জন্য কুকি প্রয়োজন। সেটিংসে যান।',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/settings');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCookieLoaded = context.watch<AppProvider>().isCookieLoaded;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2442),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'XHS Downloader',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Download History',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Hero Section ---
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2442), Color(0xFFFF6B81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2442).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.video_collection_rounded, color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '小红书 Video Downloader',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- Cookie Status Banner ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCookieLoaded
                    ? Colors.green.withOpacity(0.12)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCookieLoaded ? Colors.green.shade700 : Colors.orange.shade700,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCookieLoaded ? Icons.verified_user_rounded : Icons.lock_open_rounded,
                    color: isCookieLoaded ? Colors.greenAccent : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCookieLoaded ? 'Cookie Loaded ✓' : 'Cookie Not Loaded',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCookieLoaded ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          isCookieLoaded
                              ? 'Profile batch download is ready.'
                              : 'Required for profile batch download.',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (!isCookieLoaded)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                      child: const Text('Setup', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Link Input Field ---
            const Text(
              'Paste XHS Link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _linkController,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste short link (xhslink.com/xxxx)\nor full profile/post URL here...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF2442), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _linkController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38),
                          onPressed: () {
                            _linkController.clear();
                            setState(() {});
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.paste_rounded, color: Colors.white38),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              _linkController.text = data!.text!;
                              setState(() {});
                            }
                          },
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 28),

            // --- Profile Batch Download Button ---
            _buildPrimaryButton(
              onPressed: _handleProfileDownload,
              icon: Icons.people_alt_rounded,
              label: 'প্রোফাইল স্ক্র্যাপ + সব ভিডিও ডাউনলোড',
              sublabel: 'Scrape Profile + Download All Videos',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2442), Color(0xFFD90026)],
              ),
            ),
            const SizedBox(height: 16),

            // --- Single Video Download Button ---
            _buildSecondaryButton(
              onPressed: _handleSingleDownload,
              icon: Icons.video_call_rounded,
              label: 'সিঙ্গেল ভিডিও ডাউনলোড',
              sublabel: 'Download Single Video / Note',
            ),
            const SizedBox(height: 32),

            // --- Info Cards ---
            Row(
              children: [
                Expanded(child: _buildInfoCard(Icons.high_quality_rounded, 'No Watermark', 'Highest quality')),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.folder_open_rounded, 'Auto Save', 'XHS_Downloads/')),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.speed_rounded, 'Fast', 'Batch mode')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String sublabel,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2442).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3D3D), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2442).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.video_call_rounded, color: Color(0xFFFF2442), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF2442), size: 22),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
