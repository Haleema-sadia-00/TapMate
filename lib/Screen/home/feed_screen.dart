import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'profile_screen.dart';
import 'comments_screen.dart';
import 'storage_selection_dialog.dart';
import 'download_progress_screen.dart';
import '../../auth_provider.dart';
import '../../theme_provider.dart';

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

  // Sample feed content
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
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final isGuest = authProvider.isGuest;
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - FIXED HEIGHT
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isGuest ? 15 : 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isGuest ? 'Community Feed' : 'Community Feed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGuest
                                  ? 'Sign up to download videos'
                                  : 'Discover content from the community',
                              style: const TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isGuest)
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white, size: 22),
                              onPressed: () {
                                Navigator.pushNamed(context, '/search');
                              },
                              tooltip: 'Search',
                            ),
                          IconButton(
                            icon: Icon(
                              isGuest ? Icons.info_outline : Icons.share,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              if (isGuest) {
                                _showGuestInfo();
                              } else {
                                _showShareOptions();
                              }
                            },
                            tooltip: isGuest ? 'Info' : 'Share',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_open, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text(
                            'Guest Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showSignUpPrompt,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Upgrade',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Feed Content - SIMPLE
            Expanded(
              child: isGuest ? _buildGuestFeed(isDarkMode) : _buildCommunityFeed(isDarkMode),
            ),

            // Bottom Navigation Bar
            SafeArea(
              top: false,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                    _buildNavItem(Icons.home_rounded, 'Home', false, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.explore_rounded, 'Discover', false, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.feed_rounded, 'Feed', true, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.message_rounded, 'Message', false, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.person_rounded, 'Profile', false, context, isGuest, isDarkMode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== GUEST FEED ==================
  Widget _buildGuestFeed(bool isDarkMode) {
    return Column(
      children: [
        // Guest message banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guest Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF3B1C32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign up to download videos and access all features',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _showSignUpPrompt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text(
                        'Sign Up Free',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // REAL COMMUNITY FEED (same as logged in users, but with locked download)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _feedItems.length,
            itemBuilder: (context, index) {
              return _buildGuestFeedItem(_feedItems[index], isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuestFeedItem(Map<String, dynamic> item, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                    backgroundColor: const Color(0x33A64D79),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF3B1C32),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1AA64D79),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['platform'] as String,
                              style: const TextStyle(
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
                  icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : const Color(0xFF3B1C32)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF3B1C32),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions with LOCKED download button for guest
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button (enabled)
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
                  isDarkMode: isDarkMode,
                ),

                // Comment button (enabled)
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
                  isDarkMode: isDarkMode,
                ),

                // Share button (enabled)
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _formatNumber(item['shares'] as int),
                  onTap: () {
                    _shareContent(item);
                  },
                  isDarkMode: isDarkMode,
                ),

                // LOCKED Download button for guest
                GestureDetector(
                  onTap: () {
                    _showFeatureLockedDialog('Download');
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== COMMUNITY FEED ==================
  Widget _buildCommunityFeed(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        return _buildFeedItem(_feedItems[index], isDarkMode);
      },
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                    backgroundColor: const Color(0x33A64D79),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF3B1C32),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1AA64D79),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['platform'] as String,
                              style: const TextStyle(
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
                  icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : const Color(0xFF3B1C32)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF3B1C32),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  isDarkMode: isDarkMode,
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
                  isDarkMode: isDarkMode,
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _formatNumber(item['shares'] as int),
                  onTap: () {
                    _shareContent(item);
                  },
                  isDarkMode: isDarkMode,
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
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== HELPER WIDGETS ==================
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(color.withOpacity(0.1), Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isLocked ? Colors.grey : color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (isLocked)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock,
                size: 14,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1AA64D79),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B1C32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            isLocked ? Icons.lock : Icons.check_circle,
            color: isLocked ? Colors.orange : Colors.green,
            size: 20,
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
    bool isDarkMode = false,
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
              color: isLiked ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon,
      String label,
      bool isActive,
      BuildContext context,
      bool isGuest,
      bool isDarkMode,
      ) {
    final bool isLocked = isGuest && (label == 'Message' || label == 'Profile');

    return GestureDetector(
      onTap: isLocked
          ? () {
        _showFeatureLockedDialog(label);
      }
          : () {
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
          Stack(
            children: [
              Icon(
                icon,
                color: isActive ? primaryColor : (isDarkMode ? Colors.grey[600] : Colors.grey),
                size: 24,
              ),
              if (isLocked)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 10,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? primaryColor : (isDarkMode ? Colors.grey[600] : Colors.grey),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ================== HELPER FUNCTIONS ==================
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showGuestInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Mode'),
        content: const Text(
          'You are browsing in guest mode. Sign up to:\n\n'
              '• Download unlimited videos\n'
              '• Access community feed\n'
              '• Save videos to cloud\n'
              '• Chat with other users\n'
              '• Create your profile',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFeatureLockedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Locked'),
        content: Text('Sign up to access $feature and all premium features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSignUpPrompt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add, size: 60, color: primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Join TapMate Community',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B1C32),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign up to unlock all features and start downloading!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Sign Up Free',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
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
        contentTitle: contentItem['title'] as String,
        onDeviceStorageSelected: (path, format, quality) {
          Navigator.pop(context);
          _handleDeviceStorageDownload(path, format, quality, contentItem);
        },
        onAppStorageSelected: (format, quality) {
          Navigator.pop(context);
          _handleAppStorageDownload(format, quality, contentItem);
        },
      ),
    );
  }
// FeedScreen.dart mai yeh do functions update karo:
// feed_screen.dart میں یہ دو functions اپڈیٹ کریں:

  void _handleDeviceStorageDownload(String? path, String format, String quality, Map<String, dynamic> item) {
    if (path != null && path.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DownloadProgressScreen(
            platformName: item['platform'] as String,
            contentTitle: '${item['title']} ($format - $quality)',
            storagePath: path,
            isDeviceStorage: true,
            fromPlatformScreen: false, // ✅ Feed سے ہو تو FALSE
            sourcePlatform: 'feed', // ✅ 'feed' set کریں
          ),
        ),
      );
    }
  }

  void _handleAppStorageDownload(String format, String quality, Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProgressScreen(
          platformName: item['platform'] as String,
          contentTitle: '${item['title']} ($format - $quality)',
          isDeviceStorage: false,
          fromPlatformScreen: false, // ✅ Feed سے ہو تو FALSE
          sourcePlatform: 'feed', // ✅ 'feed' set کریں
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
            const Text(
              'Share Content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B1C32),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.green),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: primaryColor),
              title: const Text('Download & Share'),
              onTap: () {
                Navigator.pop(context);
                _showStorageSelectionDialog(item);
              },
            ),
          ],
        ),
      ),
    );
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
              'Share App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B1C32),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share TapMate with friends'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.orange),
              title: const Text('Rate on App Store'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.green),
              title: const Text('Send Feedback'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}