import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_item.dart';  // ✅ Import model (has storageType)

class DownloadLibraryScreen extends StatefulWidget {
  const DownloadLibraryScreen({super.key});

  @override
  State<DownloadLibraryScreen> createState() => _DownloadLibraryScreenState();
}

class _DownloadLibraryScreenState extends State<DownloadLibraryScreen> {
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;
  String _filterPlatform = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('download_history') ?? [];

      setState(() {
        _downloads = history.map((item) {
          try {
            final data = jsonDecode(item);
            final downloadItem = DownloadItem.fromJson(data);
            // ✅ ONLY show app storage downloads in library
            if (downloadItem.storageType == 'app') {
              return downloadItem;
            }
            return null;
          } catch (e) {
            return null;
          }
        }).whereType<DownloadItem>().toList();

        _downloads.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(DownloadItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete file
      try {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // File might not exist
      }

      // Remove from list
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('download_history') ?? [];
      final updated = history.where((h) {
        try {
          final data = jsonDecode(h);
          return data['id'] != item.id;
        } catch (e) {
          return true;
        }
      }).toList();
      await prefs.setStringList('download_history', updated);

      await _loadDownloads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download deleted')),
        );
      }
    }
  }

  void _playVideo(DownloadItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VideoPlayerFullScreen(filePath: item.filePath),
      ),
    );
  }

  List<DownloadItem> get _filteredDownloads {
    var filtered = _downloads;

    if (_filterPlatform != 'All') {
      filtered = filtered.where((d) => d.platform.toLowerCase() == _filterPlatform.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) =>
          d.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return 'Unknown size';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube': return Colors.red;
      case 'instagram': return const Color(0xFFE4405F);
      case 'tiktok': return Colors.black;
      case 'facebook': return const Color(0xFF1877F2);
      case 'twitter': return const Color(0xFF1DA1F2);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = _downloads.fold<int>(0, (sum, item) => sum + item.size);
    final totalCount = _downloads.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloads,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.download_done,
                  label: 'Downloads',
                  value: totalCount.toString(),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                _buildStatCard(
                  icon: Icons.storage,
                  label: 'Total Size',
                  value: _formatSize(totalSize),
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search downloads...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'All'),
                      _buildFilterChip('YouTube', 'youtube'),
                      _buildFilterChip('Instagram', 'instagram'),
                      _buildFilterChip('TikTok', 'tiktok'),
                      _buildFilterChip('Facebook', 'facebook'),
                      _buildFilterChip('Twitter', 'twitter'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Downloads List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDownloads.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _filterPlatform != 'All'
                        ? 'No matching downloads'
                        : 'No downloads yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isEmpty && _filterPlatform == 'All')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Something'),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredDownloads.length,
              itemBuilder: (context, index) {
                final download = _filteredDownloads[index];
                return Dismissible(
                  key: Key(download.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteDownload(download),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPlatformColor(download.platform),
                        child: Text(
                          download.platform[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        download.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(download.timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatSize(download.size)} • ${download.platform}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 30),
                        onPressed: () => _playVideo(download),
                        tooltip: 'Play video',
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.play_arrow, color: AppColors.primary),
                                  title: const Text('Play'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _playVideo(download);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteDownload(download);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: const Text('Share'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _shareVideo(download);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.info),
                                  title: const Text('File Info'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showFileInfo(download);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVideo(DownloadItem item) async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterPlatform == value,
        onSelected: (selected) {
          setState(() {
            _filterPlatform = value;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  void _showFileInfo(DownloadItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', item.title),
            const Divider(),
            _infoRow('Platform', item.platform),
            const Divider(),
            _infoRow('Size', _formatSize(item.size)),
            const Divider(),
            _infoRow('Path', item.filePath),
            const Divider(),
            _infoRow('Downloaded', _formatDate(item.timestamp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 REMOVED duplicate DownloadItem class - now using from models/download_item.dart

// Video Player Full Screen Widget
class _VideoPlayerFullScreen extends StatefulWidget {
  final String filePath;
  const _VideoPlayerFullScreen({required this.filePath});

  @override
  State<_VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<_VideoPlayerFullScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video file not found'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller.initialize();
      await _controller.setLooping(false);

      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _position = _controller.value.position;
            _duration = _controller.value.duration;
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });

      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play this video'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitialized
          ? Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: Colors.grey[800]!,
                    backgroundColor: Colors.grey[900]!,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                      onPressed: () {
                        final newPosition = _controller.value.position - const Duration(seconds: 10);
                        _controller.seekTo(newPosition);
                      },
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                        iconSize: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                      onPressed: () {
                        final newPosition = _controller.value.position + const Duration(seconds: 10);
                        _controller.seekTo(newPosition);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(' / ', style: TextStyle(color: Colors.white)),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}