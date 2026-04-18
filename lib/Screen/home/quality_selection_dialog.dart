import 'package:flutter/material.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/services/platform_downloader.dart';

class QualitySelectionDialog extends StatefulWidget {
  final String platformName;
  final String videoUrl;
  final String videoTitle;
  final Function(String quality) onQualitySelected;

  const QualitySelectionDialog({
    super.key,
    required this.platformName,
    required this.videoUrl,
    required this.videoTitle,
    required this.onQualitySelected,
  });

  @override
  State<QualitySelectionDialog> createState() => _QualitySelectionDialogState();
}

class _QualitySelectionDialogState extends State<QualitySelectionDialog> {
  List<String> _availableQualities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQualities();
  }

  Future<void> _fetchQualities() async {
    try {
      final downloader = PlatformDownloader();
      final platformId = _getPlatformId(widget.platformName);
      final qualities = await downloader.getAvailableQualities(platformId, widget.videoUrl);

      setState(() {
        _availableQualities = qualities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback qualities
        _availableQualities = ['best', '1080p', '720p', '480p', '360p'];
      });
    }
  }

  String _getPlatformId(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'youtube': return 'youtube';
      case 'instagram': return 'instagram';
      case 'tiktok': return 'tiktok';
      case 'facebook': return 'facebook';
      case 'twitter': return 'twitter';
      default: return 'youtube';
    }
  }

  String _getQualityLabel(String quality) {
    if (quality == 'best') return 'Best Quality (Recommended)';
    return quality;
  }

  String _getQualitySubtitle(String quality) {
    if (quality == 'best') return 'Highest available quality';
    if (quality == '1080p') return '1920x1080';
    if (quality == '720p') return '1280x720';
    if (quality == '480p') return '854x480';
    if (quality == '360p') return '640x360';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.high_quality, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Quality',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.videoTitle.length > 40 ? '${widget.videoTitle.substring(0, 40)}...' : widget.videoTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching available qualities...'),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              )
            else
              ..._availableQualities.map((quality) => Column(
                children: [
                  _buildQualityOption(
                    context,
                    _getQualityLabel(quality),
                    quality,
                    subtitle: _getQualitySubtitle(quality),
                  ),
                  if (quality != _availableQualities.last) const Divider(),
                ],
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(BuildContext context, String title, String quality, {required String subtitle}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.play_arrow, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
      onTap: () {
        Navigator.pop(context);
        widget.onQualitySelected(quality);
      },
    );
  }
}