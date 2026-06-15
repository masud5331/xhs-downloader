import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// SettingsScreen allows the user to manage cookies, download preferences, and app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _settingsBox;
  bool _highQuality = true;
  int _maxConcurrentDownloads = 2;
  int _delayBetweenDownloads = 1;
  String _proxyUrl = '';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _highQuality = _settingsBox.get('highQuality', defaultValue: true) as bool;
      _maxConcurrentDownloads = _settingsBox.get('maxConcurrent', defaultValue: 2) as int;
      _delayBetweenDownloads = _settingsBox.get('delay', defaultValue: 1) as int;
      _proxyUrl = _settingsBox.get('proxyUrl', defaultValue: '') as String;
    });
  }

  void _saveSetting(String key, dynamic value) {
    _settingsBox.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isCookieLoaded = context.watch<AppProvider>().isCookieLoaded;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Authentication Section ---
          _buildSectionHeader('Authentication', Icons.security_rounded),
          const SizedBox(height: 12),
          _buildCookieCard(context, isCookieLoaded),
          const SizedBox(height: 24),

          // --- Download Settings Section ---
          _buildSectionHeader('Download Settings', Icons.download_rounded),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Highest Quality (No Watermark)',
              subtitle: 'Always download the best available quality',
              value: _highQuality,
              onChanged: (val) {
                setState(() => _highQuality = val);
                _saveSetting('highQuality', val);
              },
            ),
            const Divider(color: Color(0xFF2E2E2E), height: 1),
            _buildSliderTile(
              title: 'Max Concurrent Downloads',
              subtitle: 'Current: $_maxConcurrentDownloads',
              value: _maxConcurrentDownloads.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (val) {
                setState(() => _maxConcurrentDownloads = val.toInt());
                _saveSetting('maxConcurrent', val.toInt());
              },
            ),
            const Divider(color: Color(0xFF2E2E2E), height: 1),
            _buildSliderTile(
              title: 'Delay Between Downloads (seconds)',
              subtitle: 'Current: ${_delayBetweenDownloads}s (prevents rate limiting)',
              value: _delayBetweenDownloads.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (val) {
                setState(() => _delayBetweenDownloads = val.toInt());
                _saveSetting('delay', val.toInt());
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- Save Location ---
          _buildSectionHeader('Save Location', Icons.folder_rounded),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.folder_open_rounded, color: Color(0xFFFF2442)),
              title: const Text('Download Folder', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                '/storage/emulated/0/XHS_Downloads/',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.lock_rounded, color: Colors.white30, size: 16),
            ),
          ]),
          const SizedBox(height: 24),

          // --- Proxy Settings ---
          _buildSectionHeader('Network / Proxy', Icons.network_check_rounded),
          const SizedBox(height: 12),
          _buildSettingsCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: TextEditingController(text: _proxyUrl),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'http://proxy-host:port (optional)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  labelText: 'HTTP Proxy URL',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.dns_rounded, color: Colors.white38),
                ),
                onSubmitted: (val) {
                  setState(() => _proxyUrl = val);
                  _saveSetting('proxyUrl', val);
                },
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // --- Danger Zone ---
          _buildSectionHeader('Data Management', Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text('Clear Download History', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Does not delete actual files', style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              onTap: () {
                Hive.box('history').clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared.')),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- About Section ---
          _buildSectionHeader('About', Icons.info_rounded),
          const SizedBox(height: 12),
          _buildSettingsCard([
            const ListTile(
              leading: Icon(Icons.apps_rounded, color: Color(0xFFFF2442)),
              title: Text('XHS Downloader', style: TextStyle(color: Colors.white)),
              subtitle: Text('Version 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            const Divider(color: Color(0xFF2E2E2E), height: 1),
            const ListTile(
              leading: Icon(Icons.code_rounded, color: Colors.white54),
              title: Text('Built with Flutter', style: TextStyle(color: Colors.white)),
              subtitle: Text('Dio • Hive • Provider • flutter_local_notifications', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCookieCard(BuildContext context, bool isCookieLoaded) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCookieLoaded ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCookieLoaded ? Icons.verified_user_rounded : Icons.no_encryption_rounded,
                    color: isCookieLoaded ? Colors.greenAccent : Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCookieLoaded ? 'Cookie Loaded' : 'No Cookie',
                        style: TextStyle(
                          color: isCookieLoaded ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isCookieLoaded
                            ? 'Profile batch download is enabled.'
                            : 'Upload cookies.txt to enable batch download.',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2E2E2E), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                      );
                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          try {
                            await context.read<AppProvider>().loadCookie(result.files.single.path!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cookie loaded successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to load cookie: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload cookies.txt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2442),
                    ),
                  ),
                ),
                if (isCookieLoaded) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await context.read<AppProvider>().clearCookie();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cookie cleared.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    tooltip: 'Clear Cookie',
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Export cookies from xiaohongshu.com using a browser extension (e.g., "Get cookies.txt LOCALLY"), then upload the file here.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color color = const Color(0xFFFF2442)}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFFF2442),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFFFF2442),
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
