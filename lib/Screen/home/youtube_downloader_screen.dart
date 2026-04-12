import 'package:flutter/material.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/home/storage_selection_dialog.dart';
import 'package:tapmate/Screen/services/platform_downloader.dart';

class YouTubeDownloaderScreen extends StatefulWidget {
  const YouTubeDownloaderScreen({super.key});

  @override
  State<YouTubeDownloaderScreen> createState() => _YouTubeDownloaderScreenState();
}

class _YouTubeDownloaderScreenState extends State<YouTubeDownloaderScreen> {
  final TextEditingController _linkController = TextEditingController();
  String _platformName = 'YouTube';
  bool _isDownloading = false;
  bool _autoDownloadQueued = false;
  double _progress = 0;
  String _status = 'Paste a YouTube link and tap Download';
  String? _savedFilePath;

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
      final capturedAtRaw = args['capturedAt']?.toString();
      if (capturedAtRaw != null && capturedAtRaw.isNotEmpty) {
        _status = 'Captured at $capturedAtRaw. Preparing download...';
      }

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
    _linkController.dispose();
    super.dispose();
  }

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
      builder: (context) => StorageSelectionDialog(
        platformName: _platformName,
        contentId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        contentTitle: '${_platformName} Video',
        onDeviceStorageSelected: (path, format, quality) {
          _startDownload(
            customPath: path,
            format: format,
            quality: quality,
          );
        },
        onAppStorageSelected: (format, quality) {
          _startDownload(
            format: format,
            quality: quality,
          );
        },
      ),
    );
  }

  Future<void> _startDownload({
    String? customPath,
    required String format,
    required String quality,
  }) async {
    final url = _linkController.text.trim();

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _savedFilePath = null;
      _status = customPath != null
          ? 'Starting download to selected folder...'
          : 'Starting download...';
    });

    final downloader = PlatformDownloader();
    final platformId = _platformIdFromName(_platformName);

    final result = await downloader.downloadVideo(
      platformId: platformId,
      videoUrl: url,
      videoTitle: '${platformId}_video',
      format: format,
      quality: quality,
      customPath: customPath,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress.progress.clamp(0.0, 1.0);
          final downloadedMb = (progress.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMb = progress.totalBytes > 0
              ? (progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)
              : '...';
          _status = 'Downloading $downloadedMb MB / $totalMb MB';
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _savedFilePath = result.filePath;
      
      if (result.success) {
        _status = customPath != null
            ? 'Saved in selected folder'
            : 'Saved in Download/TapMate/$platformId';
      } else {
        // Format error message based on platform
        if (_platformName.toLowerCase() == 'facebook' && result.message.contains('backend')) {
          _status = '❌ Facebook: Video might be private or protected. Try another video.';
        } else if (_platformName.toLowerCase() == 'facebook') {
          _status = '❌ Facebook: ${result.message}';
        } else {
          _status = result.message;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success 
            ? '✅ Download complete!' 
            : result.message.contains('facebook') || result.message.contains('private')
              ? 'Facebook video download failed. Please check the video is public and not protected.'
              : result.message
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: Duration(seconds: result.success ? 2 : 4),
      ),
    );
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

  Color _platformColor() {
    switch (_platformName.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'tiktok':
        return const Color(0xFF111111);
      case 'youtube':
        return Colors.red;
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return AppColors.primary;
    }
  }

  String _hintByPlatform() {
    switch (_platformName.toLowerCase()) {
      case 'instagram':
        return 'https://www.instagram.com/reel/.../';
      case 'tiktok':
        return 'https://www.tiktok.com/@user/video/...';
      case 'youtube':
        return 'https://www.youtube.com/shorts/GR_rQKROEGE';
      case 'facebook':
        return 'https://www.facebook.com/reel/...';
      case 'twitter':
        return 'https://x.com/username/status/...';
      default:
        return 'https://example.com/video/...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_platformName Downloader'),
        backgroundColor: _platformColor(),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste video link',
              style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _hintByPlatform(),
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            if (_platformName.toLowerCase() == 'facebook') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1877F2).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  '💡 Tip: Facebook videos must be public. Private or protected videos cannot be downloaded.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1877F2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadVideo,
              icon: const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Choose Location & Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _platformColor(),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _isDownloading ? _progress : null,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              style: const TextStyle(color: AppColors.textMain),
            ),
            if (_savedFilePath != null) ...[
              const SizedBox(height: 10),
              Text(
                _savedFilePath!,
                style: const TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
