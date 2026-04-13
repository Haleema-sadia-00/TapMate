import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';

class PlatformSelectionScreen extends StatelessWidget {
  const PlatformSelectionScreen({super.key});

  final List<Map<String, dynamic>> platforms = const [
    {'name': 'YouTube', 'icon': FontAwesomeIcons.youtube, 'color': Color(0xFFFF0000), 'desc': 'Download any video, short or live'},
    {'name': 'Instagram', 'icon': FontAwesomeIcons.instagram, 'color': Color(0xFFE4405F), 'desc': 'Download reels, posts & stories'},
    {'name': 'TikTok', 'icon': FontAwesomeIcons.tiktok, 'color': Color(0xFF111111), 'desc': 'Download videos without watermark'},
    {'name': 'Facebook', 'icon': FontAwesomeIcons.facebook, 'color': Color(0xFF1877F2), 'desc': 'Download public reels & videos'},
    {'name': 'Twitter', 'icon': FontAwesomeIcons.twitter, 'color': Color(0xFF1DA1F2), 'desc': 'Download videos & GIFs'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      body: Column(
        children: [
          // Header with gradient (same as home screen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Download Videos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Paste link or browse to download',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final platform = platforms[index];
                return _buildPlatformCard(
                  context,
                  platform['name'],
                  platform['icon'],
                  platform['color'],
                  platform['desc'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(
      BuildContext context,
      String name,
      IconData icon,
      Color color,
      String desc,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPlatformOptions(context, name, color),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FaIcon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlatformOptions(BuildContext context, String platformName, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.download, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Download from $platformName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.link,
              title: 'Paste Link',
              subtitle: 'Directly paste video URL',
              color: color,
              onTap: () {
                Navigator.pop(context);
                _showLinkInputDialog(context, platformName, color);
              },
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.open_in_browser,
              title: 'Browse & Select',
              subtitle: 'Open $platformName and copy link',
              color: color,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/live-platform-browser',
                  arguments: {
                    'platform': platformName,
                    'url': _getPlatformUrl(platformName),
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  void _showLinkInputDialog(BuildContext context, String platformName, Color color) {
    final TextEditingController linkController = TextEditingController();
    final hint = _getUrlHint(platformName);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.link, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste $platformName Link',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Copy the video link from the app and paste below:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: linkController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.link, color: color),
                  // 🔥 FIX: Prevent overflow
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13), // 🔥 Smaller font to prevent overflow
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (linkController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _navigateToDownload(context, linkController.text.trim(), platformName);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlatformUrl(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'youtube':
        return 'https://youtube.com';
      case 'instagram':
        return 'https://instagram.com';
      case 'tiktok':
        return 'https://tiktok.com';
      case 'facebook':
        return 'https://facebook.com';
      case 'twitter':
        return 'https://twitter.com';
      default:
        return 'https://youtube.com';
    }
  }

  String _getUrlHint(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'youtube':
        return 'https://youtube.com/watch?v=...';
      case 'instagram':
        return 'https://instagram.com/reel/...';
      case 'tiktok':
        return 'https://tiktok.com/@user/video/...';
      case 'facebook':
        return 'https://facebook.com/reel/...';
      case 'twitter':
        return 'https://twitter.com/user/status/...';
      default:
        return 'Paste video URL here...';
    }
  }

  void _navigateToDownload(BuildContext context, String videoUrl, String platformName) {
    Navigator.pushNamed(
      context,
      '/youtube_downloader',
      arguments: {
        'url': videoUrl,
        'platform': platformName,
      },
    );
  }
}