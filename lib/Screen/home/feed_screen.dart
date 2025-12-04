import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'profile_screen.dart';
import 'comments_screen.dart';
import 'storage_selection_dialog.dart';
import 'download_progress_screen.dart';

// Theme Colors
const Color primaryColor = Color(0xFFA64D79);
const Color secondaryColor = Color(0xFF6A1E55);
const Color darkPurple = Color(0xFF3B1C32);

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _selectedContentId;
  bool _isContentSelected = false;

  // Sample feed content - in real app, this would come from API
  final List<Map<String, dynamic>> _feedItems = [
    {
      'id': '1',
      'user': 'John Doe',
      'avatar': '👤',
      'title': 'Amazing sunset video from my trip',
      'thumbnail': '🌅',
      'platform': 'Instagram',
      'likes': 1250,
      'comments': 89,
      'shares': 45,
      'time': '2h ago',
      'isLiked': false,
    },
    {
      'id': '2',
      'user': 'Sarah Smith',
      'avatar': '👩',
      'title': 'Check out this cooking tutorial!',
      'thumbnail': '👨‍🍳',
      'platform': 'YouTube',
      'likes': 3420,
      'comments': 234,
      'shares': 156,
      'time': '5h ago',
      'isLiked': false,
    },
    {
      'id': '3',
      'user': 'Mike Johnson',
      'avatar': '🧑',
      'title': 'Dance challenge video',
      'thumbnail': '💃',
      'platform': 'TikTok',
      'likes': 8900,
      'comments': 567,
      'shares': 890,
      'time': '1d ago',
      'isLiked': false,
    },
    {
      'id': '4',
      'user': 'Emma Wilson',
      'avatar': '👱‍♀️',
      'title': 'Travel vlog from Japan',
      'thumbnail': '✈️',
      'platform': 'YouTube',
      'likes': 5670,
      'comments': 345,
      'shares': 234,
      'time': '2d ago',
      'isLiked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkPurple, secondaryColor, primaryColor],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: darkPurple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Feed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white),
                                onPressed: () {
                                  // TODO: Implement search
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.white),
                                onPressed: () {
                                  _showShareOptions();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Discover content from the community',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Feed Content
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _feedItems.length,
                    itemBuilder: (context, index) {
                      return _buildFeedItem(_feedItems[index]);
                    },
                  ),
                ),

                // Bottom Navigation Bar
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_rounded, 'Home', false, context),
                      _buildNavItem(Icons.explore_rounded, 'Discover', false, context),
                      _buildNavItem(Icons.feed_rounded, 'Feed', true, context),
                      _buildNavItem(Icons.message_rounded, 'Message', false, context),
                      _buildNavItem(Icons.person_rounded, 'Profile', false, context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button
          if (_isContentSelected)
            Positioned(
              right: 20,
              bottom: 90,
              child: FloatingActionButton.extended(
                onPressed: () {
                  _showStorageSelectionDialog();
                },
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.download_rounded, size: 24),
                label: const Text(
                  'Download',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: darkPurple.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userName: item['user'] as String,
                          userAvatar: item['avatar'] as String,
                          followers: 1250,
                          following: 450,
                          posts: 23,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Text(
                      item['avatar'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                userName: item['user'] as String,
                                userAvatar: item['avatar'] as String,
                                followers: 1250,
                                following: 450,
                                posts: 23,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          item['user'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkPurple,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['platform'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: darkPurple),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Content Thumbnail
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedContentId = item['id'] as String;
                _isContentSelected = true;
              });
            },
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: _selectedContentId == item['id']
                      ? primaryColor
                      : Colors.transparent,
                  width: _selectedContentId == item['id'] ? 3 : 0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['thumbnail'] as String,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedContentId == item['id'])
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: item['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                  label: _formatNumber(item['likes'] as int),
                  onTap: () {
                    setState(() {
                      if (item['isLiked'] == true) {
                        item['isLiked'] = false;
                        item['likes'] = (item['likes'] as int) - 1;
                      } else {
                        item['isLiked'] = true;
                        item['likes'] = (item['likes'] as int) + 1;
                      }
                    });
                  },
                  isLiked: item['isLiked'] == true,
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: _formatNumber(item['comments'] as int),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          contentTitle: item['title'] as String,
                          initialCommentCount: item['comments'] as int,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _formatNumber(item['shares'] as int),
                  onTap: () {
                    _shareContent(item);
                  },
                ),
                _buildActionButton(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  onTap: () {
                    setState(() {
                      _selectedContentId = item['id'] as String;
                      _isContentSelected = true;
                    });
                    _showStorageSelectionDialog(item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isLiked ? Colors.red : primaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isLiked ? Colors.red : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPurple,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: primaryColor),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: primaryColor),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement native share
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareContent(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share "${item['title']}"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkPurple,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link, 'Copy Link', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                }),
                _buildShareOption(Icons.share, 'Share', () {
                  Navigator.pop(context);
                  // TODO: Implement native share
                }),
                _buildShareOption(Icons.download, 'Download', () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedContentId = item['id'] as String;
                    _isContentSelected = true;
                  });
                  _showStorageSelectionDialog(item);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: darkPurple,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageSelectionDialog([Map<String, dynamic>? item]) {
    final contentItem = item ?? _feedItems.firstWhere(
      (i) => i['id'] == _selectedContentId,
      orElse: () => _feedItems[0],
    );

    showDialog(
      context: context,
      builder: (context) => StorageSelectionDialog(
        platformName: contentItem['platform'] as String,
        contentId: contentItem['id'] as String,
        onDeviceStorageSelected: (path) {
          Navigator.pop(context);
          _handleDeviceStorageDownload(path, contentItem);
        },
        onAppStorageSelected: () {
          Navigator.pop(context);
          _handleAppStorageDownload(contentItem);
        },
      ),
    );
  }

  void _handleDeviceStorageDownload(String? path, Map<String, dynamic> item) {
    if (path != null && path.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DownloadProgressScreen(
            platformName: item['platform'] as String,
            contentTitle: item['title'] as String,
            storagePath: path,
            isDeviceStorage: true,
          ),
        ),
      );
    }
  }

  void _handleAppStorageDownload(Map<String, dynamic> item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProgressScreen(
          platformName: item['platform'] as String,
          contentTitle: item['title'] as String,
          isDeviceStorage: false,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (label == 'Discover') {
          Navigator.pushReplacementNamed(context, '/search');
        } else if (label == 'Feed') {
          Navigator.pushReplacementNamed(context, '/feed');
        } else if (label == 'Message') {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (label == 'Profile') {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? primaryColor : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

