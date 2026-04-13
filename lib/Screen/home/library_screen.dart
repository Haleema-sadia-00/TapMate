import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tapmate/Screen/constants/app_colors.dart';

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
            return DownloadItem.fromJson(data);
          } catch (e) {
            return null;
          }
        }).whereType<DownloadItem>().toList();

        // Sort by newest first
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

  List<DownloadItem> get _filteredDownloads {
    var filtered = _downloads;

    if (_filterPlatform != 'All') {
      filtered = filtered.where((d) => d.platform == _filterPlatform).toList();
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
        title: const Text('Download History'),
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
                          Text(
                            '${_formatSize(download.size)} • ${download.platform}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () {
                          // Play video (you can implement video player)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video player coming soon')),
                          );
                        },
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.delete),
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
                                    // Implement share
                                    Navigator.pop(context);
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
            Text('Name: ${item.title}'),
            const SizedBox(height: 8),
            Text('Platform: ${item.platform}'),
            const SizedBox(height: 8),
            Text('Size: ${_formatSize(item.size)}'),
            const SizedBox(height: 8),
            Text('Path: ${item.filePath}'),
            const SizedBox(height: 8),
            Text('Downloaded: ${_formatDate(item.timestamp)}'),
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
}

class DownloadItem {
  final String id;
  final String platform;
  final String title;
  final String filePath;
  final int size;
  final DateTime timestamp;

  DownloadItem({
    required this.id,
    required this.platform,
    required this.title,
    required this.filePath,
    required this.size,
    required this.timestamp,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      platform: json['platform'],
      title: json['title'],
      filePath: json['filePath'],
      size: json['size'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'title': title,
      'filePath': filePath,
      'size': size,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}