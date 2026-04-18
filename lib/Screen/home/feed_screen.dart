import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'package:tapmate/Screen/home/comments_screen.dart';
import 'package:tapmate/Screen/home/other_user_profile_screen.dart';
import '../../auth_provider.dart';
import '../../theme_provider.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoading = false;
  String? _lastVisible;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadFeedItems();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedItems() async {
    setState(() => _isLoading = true);

    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> posts = [];

      for (var doc in postsSnapshot.docs) {
        Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;

        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(postData['userId'])
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

        String? currentUserId = _auth.currentUser?.uid;
        bool isLiked = false;
        if (currentUserId != null) {
          DocumentSnapshot likeDoc = await _firestore
              .collection('posts')
              .doc(doc.id)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        posts.add({
          'id': doc.id,
          'user_id': postData['userId'],
          'user_name': userData['name'] ?? 'Unknown User',
          'user_profile_pic': userData['profilePic'] ?? userData['profile_pic'] ?? '',
          'user_username': userData['username'] ?? '',
          'caption': postData['caption'] ?? '',
          'thumbnail_url': postData['thumbnailUrl'] ?? '',
          'video_url': postData['videoUrl'] ?? '',
          'platform': postData['platform'] ?? 'TapMate',
          'created_at': postData['createdAt'],
          'likes_count': postData['likes'] ?? 0,
          'comments_count': postData['comments'] ?? 0,
          'is_video': postData['isVideo'] ?? false,
          'is_liked': isLiked,
        });
      }

      setState(() {
        _feedItems = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    String postId = _feedItems[index]['id'];
    bool isLiked = _feedItems[index]['is_liked'] ?? false;

    if (!isLiked) {
      _animationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 300), () {
        _animationController.reset();
      });
    }

    setState(() {
      _feedItems[index]['is_liked'] = !isLiked;
      _feedItems[index]['likes_count'] =
          (_feedItems[index]['likes_count'] as int) + (isLiked ? -1 : 1);
    });

    try {
      if (isLiked) {
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('likes')
            .doc(currentUserId)
            .delete();
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('likes')
            .doc(currentUserId)
            .set({
          'userId': currentUserId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      setState(() {
        _feedItems[index]['is_liked'] = isLiked;
        _feedItems[index]['likes_count'] =
            (_feedItems[index]['likes_count'] as int) + (isLiked ? 1 : -1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          userId: userId,
          userName: '',
          userAvatar: '👤',
        ),
      ),
    );
  }

  // ✅ WORKING SHARE FUNCTION
  Future<void> _sharePost(Map<String, dynamic> post) async {
    final shareText = '''
Check out this post on TapMate! 📱

${post['caption'] ?? 'Check out this amazing content'}

Posted by: ${post['user_name']}
Likes: ${post['likes_count']}
Comments: ${post['comments_count']}

Download TapMate to see more! 🚀
''';

    await Share.share(shareText);
  }

  void _copyPostLink(String postId) {
    final postLink = 'tapmate://post/$postId';
    Clipboard.setData(ClipboardData(text: postLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post link copied!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    bool isMyPost = post['user_id'] == _auth.currentUser?.uid;

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
            // Share Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: Colors.blue, size: 20),
              ),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(post);
              },
            ),
            // Copy Link Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, color: Colors.green, size: 20),
              ),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink(post['id']);
              },
            ),
            if (isMyPost) ...[
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
            ] else ...[
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add, color: AppColors.primary, size: 20),
                ),
                title: const Text('Follow User'),
                onTap: () {
                  Navigator.pop(context);
                  _followUser(post['user_id']);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block, color: Colors.red, size: 20),
                ),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(post);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag, color: Colors.orange, size: 20),
                ),
                title: const Text('Report Post', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(post);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deletePost(Map<String, dynamic> post) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('posts').doc(post['id']).delete();
                setState(() {
                  _feedItems.removeWhere((item) => item['id'] == post['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _followUser(String userId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(userId)
          .set({'followedAt': FieldValue.serverTimestamp()});
      await _firestore.collection('users').doc(userId).update({
        'followers_count': FieldValue.increment(1),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User followed'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _blockUser(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _reportPost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Please select a reason for reporting this post.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post reported'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    }
    return 'Recently';
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context, bool isGuest, bool isDarkMode) {
    final bool isLocked = isGuest && (label == 'Message' || label == 'Profile');

    return GestureDetector(
      onTap: isLocked
          ? () => _showGuestFeatureDialog(label)
          : () {
        if (label == 'Home') Navigator.pushReplacementNamed(context, '/home');
        else if (label == 'Search') Navigator.pushReplacementNamed(context, '/search');
        else if (label == 'Feed') Navigator.pushReplacementNamed(context, '/feed');
        else if (label == 'Message') Navigator.pushReplacementNamed(context, '/chat');
        else if (label == 'Profile') Navigator.pushReplacementNamed(context, '/profile');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : (isDarkMode ? Colors.grey[600] : Colors.grey),
                size: 24,
              ),
              if (isLocked)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.textMain : AppColors.lightSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 10, color: Colors.orange),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.primary : (isDarkMode ? Colors.grey[600] : Colors.grey),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Locked 🔒'),
        content: Text('Sign up to $feature and interact with the community.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sign Up', style: TextStyle(color: AppColors.lightSurface)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'tiktok': return const Color(0xFF000000);
      case 'instagram': return const Color(0xFFE4405F);
      case 'facebook': return const Color(0xFF1877F2);
      default: return AppColors.primary;
    }
  }

  void _showGuestInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Mode'),
        content: const Text(
          'You are browsing in guest mode. Sign up to:\n\n'
              '• Like and comment on posts\n'
              '• Share posts\n'
              '• Follow users\n'
              '• Create your own posts',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sign Up', style: TextStyle(color: AppColors.lightSurface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGuest = authProvider.isGuest;
    final isDarkMode = themeProvider.isDarkMode;

    if (isGuest) {
      return _buildGuestView(isDarkMode);
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(isGuest ? Icons.info_outline : Icons.search, color: Colors.white, size: 22),
                    onPressed: () {
                      if (isGuest) _showGuestInfo();
                      else Navigator.pushNamed(context, '/search');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest ? 'Community Feed' : 'Your Feed',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGuest ? 'Sign up to interact' : 'Discover content from your network',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isGuest)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pushNamed(context, '/create-post'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Feed Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFeedItems,
                color: AppColors.primary,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _feedItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.feed_outlined, size: 80, color: isDarkMode ? Colors.grey[600] : Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text('No posts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppColors.accent)),
                      const SizedBox(height: 10),
                      Text(isGuest ? 'Sign up to see content' : 'Follow people to see their posts', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _feedItems.length,
                  itemBuilder: (context, index) => _buildFeedItem(_feedItems[index], index, isGuest, isDarkMode),
                ),
              ),
            ),

            // Bottom Navigation
            SafeArea(
              top: false,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightSurface,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', false, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.search, 'Search', false, context, isGuest, isDarkMode),
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

  Widget _buildGuestView(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  'Sign In Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please sign in to see your feed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item, int index, bool isGuest, bool isDarkMode) {
    final isLiked = item['is_liked'] ?? false;
    final timestamp = item['created_at'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _viewUserProfile(item['user_id']),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: item['user_profile_pic'] != null && item['user_profile_pic'].toString().isNotEmpty
                        ? NetworkImage(item['user_profile_pic'])
                        : null,
                    child: (item['user_profile_pic'] == null || item['user_profile_pic'].toString().isEmpty)
                        ? Text(item['user_name'][0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _viewUserProfile(item['user_id']),
                        child: Text(
                          item['user_name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPlatformColor(item['platform']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['platform'],
                              style: TextStyle(fontSize: 9, color: _getPlatformColor(item['platform']), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timestamp != null ? timeago.format(timestamp.toDate()) : 'Recently',
                            style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey[500] : Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: isDarkMode ? Colors.grey[400] : AppColors.accent, size: 20),
                  onPressed: () => _showPostOptions(item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          if (item['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item['caption'],
                style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[300] : AppColors.textMain, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentsScreen(
                    postId: item['id'],
                    contentTitle: item['caption'],
                    initialCommentCount: item['comments_count'],
                  ),
                ),
              );
            },
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item['thumbnail_url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library, size: 30, color: AppColors.primary),
                            const SizedBox(height: 6),
                            Text('Preview not available', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    if (item['is_video'] == true)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)),
                  child: Icon(Icons.favorite, size: 16, color: isLiked ? Colors.red : Colors.grey[500]),
                ),
                const SizedBox(width: 4),
                Text(_formatNumber(item['likes_count']), style: TextStyle(fontSize: 12, color: isLiked ? Colors.red : Colors.grey[500])),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_formatNumber(item['comments_count']), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ✅ Action Buttons - NO DOWNLOAD (Simple & Clean)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: isLiked ? 'Liked' : 'Like',
                  color: isLiked ? Colors.red : AppColors.primary,
                  onTap: isGuest ? () => _showGuestFeatureDialog('Like posts') : () => _toggleLike(index),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          postId: item['id'],
                          contentTitle: item['caption'],
                          initialCommentCount: item['comments_count'],
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.primary,
                  onTap: () => _sharePost(item),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}