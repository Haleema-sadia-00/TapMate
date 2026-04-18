import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/services/platform_downloader.dart';
import 'package:tapmate/Screen/home/library_screen.dart';
import 'storage_selection_dialog.dart';
import '../models/download_item.dart';  // 🔥 Import DownloadItem model

class YouTubeDownloaderScreen extends StatefulWidget {
  const YouTubeDownloaderScreen({super.key});

  @override
  State<YouTubeDownloaderScreen> createState() => _YouTubeDownloaderScreenState();
}

class _YouTubeDownloaderScreenState extends State<YouTubeDownloaderScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  String _platformName = 'YouTube';
  bool _isDownloading = false;
  bool _autoDownloadQueued = false;
  double _progress = 0;
  String _status = 'Ready to download';
  String? _savedFilePath;
  String _downloadSpeed = '';
  String _eta = '';
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  String _storageInfo = '';
  bool _hasStoragePermission = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkStoragePermission();
    _getStorageInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final initialUrl = args['url']?.toString() ?? '';
      final selectedPlatform = args['platform']?.toString();

      if (selectedPlatform != null && selectedPlatform.isNotEmpty) {
        _platformName = selectedPlatform;
      }

      if (_linkController.text.isEmpty && initialUrl.isNotEmpty) {
        _linkController.text = initialUrl;
      }

      final autoDownload = args['autoDownload'] == true;
      if (autoDownload && !_autoDownloadQueued && initialUrl.isNotEmpty) {
        _autoDownloadQueued = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isDownloading) return;
          _downloadVideo();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      setState(() {
        _hasStoragePermission = status.isGranted;
      });

      if (!status.isGranted) {
        final result = await Permission.storage.request();
        setState(() {
          _hasStoragePermission = result.isGranted;
        });
      }
    } else {
      setState(() {
        _hasStoragePermission = true;
      });
    }
  }

  Future<void> _getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stats = await directory.stat();

      final totalSpace = Platform.isAndroid ? 128 * 1024 * 1024 * 1024 : 64 * 1024 * 1024 * 1024;
      final freeSpace = stats.size;
      final freeGB = (freeSpace / (1024 * 1024 * 1024)).toStringAsFixed(1);
      final totalGB = (totalSpace / (1024 * 1024 * 1024)).toStringAsFixed(1);

      setState(() {
        _storageInfo = '📱 Free: $freeGB GB / Total: $totalGB GB';
      });
    } catch (e) {
      setState(() {
        _storageInfo = 'Storage info unavailable';
      });
    }
  }

  // 🔥 Only storage selection dialog
  Future<void> _downloadVideo() async {
    final url = _linkController.text.trim();

    if (url.isEmpty || !_isValidUrlForPlatform(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid $_platformName link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StorageSelectionDialog(
        platformName: _platformName,
        contentId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        contentTitle: '${_platformName} Video',
        onDeviceStorageSelected: (path, format, quality) {
          _startDownload(url, customPath: path);
        },
        onAppStorageSelected: (format, quality) {
          _startDownload(url, customPath: null);
        },
      ),
    );
  }

  // 🔥 Start download with best quality and save storage type
  void _startDownload(String url, {String? customPath}) async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _savedFilePath = null;
      _downloadSpeed = '';
      _eta = '';
      _downloadedBytes = 0;
      _totalBytes = 0;
      _status = customPath != null
          ? '📁 Downloading to selected folder with best quality...'
          : '📁 Downloading to App Storage with best quality...';
    });

    final downloader = PlatformDownloader();
    final platformId = _platformIdFromName(_platformName);
    final startTime = DateTime.now();

    final result = await downloader.downloadVideo(
      platformId: platformId,
      videoUrl: url,
      videoTitle: '${_platformName}_video_${DateTime.now().millisecondsSinceEpoch}',
      format: 'mp4',
      quality: 'best',
      customPath: customPath,
      onProgress: (progress) {
        if (!mounted) return;

        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final downloadedMB = progress.downloadedBytes / (1024 * 1024);
        final speed = elapsed == 0 ? 0 : downloadedMB / elapsed;

        if (progress.totalBytes > 0 && speed > 0) {
          final remainingBytes = progress.totalBytes - progress.downloadedBytes;
          final etaSeconds = remainingBytes / (speed * 1024 * 1024);

          setState(() {
            _downloadSpeed = '⚡ ${speed.toStringAsFixed(1)} MB/s';
            _eta = etaSeconds.isFinite && etaSeconds > 0
                ? '⏱️ ${etaSeconds.toInt()} sec left'
                : '';
          });
        } else if (speed > 0) {
          setState(() {
            _downloadSpeed = '⚡ ${speed.toStringAsFixed(1)} MB/s';
          });
        }

        setState(() {
          _progress = progress.progress.clamp(0.0, 1.0);
          _downloadedBytes = progress.downloadedBytes;
          _totalBytes = progress.totalBytes;

          final downloadedMb = (progress.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMb = progress.totalBytes > 0
              ? (progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)
              : '...';
          _status = '📥 $downloadedMb MB / $totalMb MB';
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _savedFilePath = result.filePath;

      if (result.success) {
        _status = '✅ Download complete!';
        _progress = 1.0;

        final storageType = customPath != null ? 'device' : 'app';

        _saveToDownloadHistory(
          platform: _platformName,
          title: result.videoTitle ?? '${_platformName} Video',
          filePath: result.filePath!,
          size: _downloadedBytes,
          storageType: storageType,
        );
      } else {
        _status = '❌ ${result.message}';
      }
    });

    if (result.success) {
      final storageType = customPath != null ? 'device' : 'app';

      if (storageType == 'app') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('Download complete! View in Library')),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/download_library'),
                  child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final fileName = result.filePath!.split('/').last;
        final folderPath = customPath ?? 'Selected folder';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Download complete!', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('📁 $folderPath', style: TextStyle(fontSize: 12)),
                Text('📹 $fileName', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    _getStorageInfo();
  }
  // 🔥 UPDATED: Save with storage type
  Future<void> _saveToDownloadHistory({
    required String platform,
    required String title,
    required String filePath,
    required int size,
    required String storageType, // 🔥 NEW parameter
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('download_history') ?? [];

      final newEntry = jsonEncode({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'platform': platform,
        'title': title,
        'filePath': filePath,
        'size': size,
        'timestamp': DateTime.now().toIso8601String(),
        'storageType': storageType, // 🔥 Save storage type
      });

      history.add(newEntry);
      await prefs.setStringList('download_history', history);
      print('✅ Saved: $title (${storageType} storage)');
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  bool _isValidUrlForPlatform(String input) {
    final value = input.toLowerCase();
    final platform = _platformName.toLowerCase();

    if (platform == 'youtube') {
      return value.contains('youtube.com') || value.contains('youtu.be');
    }
    if (platform == 'instagram') {
      return value.contains('instagram.com');
    }
    if (platform == 'tiktok') {
      return value.contains('tiktok.com') || value.contains('vm.tiktok.com');
    }
    if (platform == 'facebook') {
      return value.contains('facebook.com') || value.contains('fb.watch');
    }
    if (platform == 'twitter') {
      return value.contains('twitter.com') || value.contains('x.com');
    }
    return false;
  }

  String _platformIdFromName(String platformName) {
    final normalized = platformName.toLowerCase();
    if (normalized == 'instagram') return 'instagram';
    if (normalized == 'tiktok') return 'tiktok';
    if (normalized == 'facebook') return 'facebook';
    if (normalized == 'twitter') return 'twitter';
    return 'youtube';
  }

  Color _getTapMateColor() {
    return AppColors.primary;
  }

  String _hintByPlatform() {
    switch (_platformName.toLowerCase()) {
      case 'instagram':
        return 'https://www.instagram.com/reel/.../';
      case 'tiktok':
        return 'https://www.tiktok.com/@user/video/...';
      case 'youtube':
        return 'https://www.youtube.com/watch?v=...';
      case 'facebook':
        return 'https://www.facebook.com/reel/...';
      case 'twitter':
        return 'https://x.com/username/status/...';
      default:
        return 'Paste video URL here...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tapMateColor = _getTapMateColor();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_platformName} Downloader'),
        backgroundColor: tapMateColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => Navigator.pushNamed(context, '/download_library'),
            tooltip: 'Download Library',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Storage Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(_hasStoragePermission ? Icons.sd_storage : Icons.warning,
                        color: _hasStoragePermission ? Colors.green : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _storageInfo.isEmpty ? 'Checking storage...' : _storageInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: _hasStoragePermission ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Link Input Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tapMateColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tapMateColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, color: tapMateColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Video Link',
                        style: TextStyle(
                          color: tapMateColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: _hintByPlatform(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: _linkController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _linkController.clear();
                          });
                        },
                      )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Download Button with Animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isDownloading ? 1.0 : _pulseAnimation.value,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadVideo,
                    icon: _isDownloading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.cloud_download),
                    label: Text(_isDownloading ? 'Downloading...' : 'DOWNLOAD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tapMateColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Progress Section
            if (_isDownloading || _progress > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_downloadSpeed.isNotEmpty)
                              Text(_downloadSpeed, style: const TextStyle(fontSize: 12)),
                            if (_eta.isNotEmpty)
                              Text(_eta, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(tapMateColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 12,
                        color: _status.contains('✅') ? Colors.green :
                        _status.contains('❌') ? Colors.red : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_savedFilePath != null && _savedFilePath!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved at: $_savedFilePath'),
                                action: SnackBarAction(
                                  label: 'VIEW',
                                  onPressed: () => Navigator.pushNamed(context, '/download_library'),
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.folder, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _savedFilePath!.split('/').last,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Tips Section
            Card(
              elevation: 0,
              color: Colors.amber[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste your video link, choose storage location, and download with best quality!',
                        style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}