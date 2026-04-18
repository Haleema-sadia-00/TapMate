import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/services/follow_service.dart';
import 'package:tapmate/Screen/services/chat_service.dart';
import 'package:tapmate/Screen/home/chat_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  bool _isPrivate = false;
  bool _isRequestSent = false;
  bool _isBlocked = false;  // ✅ Added for block status

  // User data
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];

  // Services
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfCurrentUser();
    _loadUserData();
  }

  void _checkIfCurrentUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == widget.userId) {
      _isCurrentUser = true;
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // ✅ First check if current user has blocked this user
      final isBlockedByMe = await _followService.isUserBlocked(widget.userId);

      if (isBlockedByMe) {
        setState(() {
          _isBlocked = true;
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        bool isFollowing = false;
        bool isPrivate = data['is_private'] ?? false;
        bool isRequestSent = false;

        if (!_isCurrentUser) {
          isFollowing = await _followService.isFollowing(widget.userId);

          if (!isFollowing && isPrivate) {
            final requestDoc = await _firestore
                .collection('users')
                .doc(widget.userId)
                .collection('follow_requests')
                .doc(_auth.currentUser?.uid)
                .get();
            isRequestSent = requestDoc.exists;
          }
        }

        setState(() {
          _userData = {
            'id': widget.userId,
            'name': data['name'] ?? widget.userName,
            'username': data['username'] ?? 'user',
            'profile_pic': data['profile_pic'] ?? widget.userAvatar,
            'bio': data['bio'] ?? 'No bio available',
            'posts_count': data['posts_count'] ?? 0,
            'followers_count': data['followers_count'] ?? 0,
            'following_count': data['following_count'] ?? 0,
            'is_private': isPrivate,
          };
          _isFollowing = isFollowing;
          _isPrivate = isPrivate;
          _isRequestSent = isRequestSent;
          _isBlocked = false;
        });

        await _loadUserPosts();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _userPosts = postsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'thumbnail': data['thumbnailUrl'] ?? '',
            'likes': data['likes'] ?? 0,
            'isVideo': data['isVideo'] ?? false,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUser) return;
    setState(() => _isLoading = true);

    try {
      if (_isPrivate && !_isFollowing && !_isRequestSent) {
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('follow_requests')
            .doc(_auth.currentUser?.uid)
            .set({
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });
        setState(() => _isRequestSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request sent!'), backgroundColor: Colors.green),
        );
      } else if (_isFollowing) {
        await _followService.unfollowUser(widget.userId);
        setState(() {
          _isFollowing = false;
          _userData['followers_count'] = (_userData['followers_count'] ?? 0) - 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unfollowed'), backgroundColor: Colors.grey),
        );
      } else if (!_isPrivate && !_isFollowing) {
        await _followService.followUser(widget.userId);
        setState(() {
          _isFollowing = true;
          _userData['followers_count'] = (_userData['followers_count'] ?? 0) + 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Followed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_isCurrentUser) return;

    // ✅ Private account check - Only allow message if following
    if (_isPrivate && !_isFollowing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only message this user after they accept your follow request.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      String chatId = await _chatService.createChat(widget.userId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              initialChatId: chatId,
              initialUserId: widget.userId,
              initialUserName: _userData['name'] ?? widget.userName,
              initialUserAvatar: _userData['profile_pic'] ?? widget.userAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showMoreOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: AppColors.primary, size: 20),
              ),
              title: const Text('Share Profile'),
              onTap: () => _shareProfile(),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, color: Colors.green, size: 20),
              ),
              title: const Text('Copy Profile Link'),
              onTap: () => _copyProfileLink(),
            ),
            const Divider(),
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
              onTap: () => _showBlockDialog(),
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
              title: const Text('Report User', style: TextStyle(color: Colors.orange)),
              onTap: () => _showReportDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final shareText = '''
Check out ${_userData['name']}'s profile on TapMate! 👤

Username: @${_userData['username']}
Bio: ${_userData['bio']}
Followers: ${_userData['followers_count']}
Posts: ${_userData['posts_count']}

Follow them on TapMate!
''';
    await Share.share(shareText);
  }

  Future<void> _copyProfileLink() async {
    final profileLink = 'tapmate://user/${widget.userId}';
    await Clipboard.setData(ClipboardData(text: profileLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile link copied!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${_userData['name']}? They will not be able to:\n\n• Follow you\n• Send you messages\n• View your posts\n• Interact with you'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    setState(() => _isLoading = true);

    try {
      // Call block service
      await _followService.blockUser(widget.userId);

      // Update local state
      setState(() {
        _isBlocked = true;
        _isFollowing = false;
        _isRequestSent = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_userData['name']} has been blocked'),
            backgroundColor: Colors.red,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Please select a reason for reporting this user.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedView(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _userData['name'] ?? widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: _showMoreOptions,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You blocked ${_userData['name']}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'To unblock them, go to Settings > Blocked Users',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Go Back'),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  Widget _buildProfilePicture() {
    String? profilePic = _userData['profile_pic'];

    if (profilePic != null && profilePic.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            profilePic,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
          ),
        ),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(_userData['name'] ?? 'U'),
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.accent)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
      ],
    );
  }

  Widget _buildPostThumbnail(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (post['thumbnail'] != null && post['thumbnail'].toString().isNotEmpty)
            Image.network(
              post['thumbnail'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image),
            ),
          Positioned(
            bottom: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(post['likes'] ?? 0),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (post['isVideo'] == true)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Show blocked view if user is blocked
    if (_isBlocked) {
      return _buildBlockedView(isDarkMode);
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
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
                  colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _userData['name'] ?? widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: _showMoreOptions,
                    ),
                ],
              ),
            ),

            // Profile Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildProfilePicture(),
                              const SizedBox(width: 30),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn('Posts', _formatNumber(_userData['posts_count'] ?? 0)),
                                    _buildStatColumn('Followers', _formatNumber(_userData['followers_count'] ?? 0)),
                                    _buildStatColumn('Following', _formatNumber(_userData['following_count'] ?? 0)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _userData['name'] ?? widget.userName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : AppColors.accent,
                                      ),
                                    ),
                                    if (_isPrivate && !_isFollowing && !_isCurrentUser)
                                      const Icon(Icons.lock, size: 14, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '@${_userData['username'] ?? 'user'}',
                                  style: TextStyle(fontSize: 14, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _userData['bio'] ?? 'No bio available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[300] : AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          if (!_isCurrentUser)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _toggleFollow,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isFollowing
                                              ? Colors.grey
                                              : (_isRequestSent ? Colors.orange : AppColors.primary),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          _isFollowing
                                              ? 'Following'
                                              : (_isRequestSent ? 'Request Sent' : 'Follow'),
                                          style: TextStyle(
                                            color: (_isFollowing || _isRequestSent) ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!_isPrivate || (_isPrivate && _isFollowing))
                                      const SizedBox(width: 12),
                                    if (!_isPrivate || (_isPrivate && _isFollowing))
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _sendMessage,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.primary, width: 2),
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.message, color: AppColors.primary, size: 18),
                                              const SizedBox(width: 6),
                                              const Text('Message'),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_isPrivate && !_isFollowing && !_isCurrentUser && !_isRequestSent)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.lock, size: 16, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This account is private. Send a follow request to see their posts and message them.',
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Tabs
                    if (_isFollowing || !_isPrivate || _isCurrentUser) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey,
                          indicatorColor: AppColors.primary,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                            Tab(icon: Icon(Icons.play_circle_outline), text: 'Reels'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _userPosts.isEmpty
                                ? _buildEmptyState('No posts yet', Icons.photo_library)
                                : GridView.builder(
                              padding: const EdgeInsets.all(2),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemCount: _userPosts.length,
                              itemBuilder: (context, index) =>
                                  _buildPostThumbnail(_userPosts[index]),
                            ),
                            _userPosts.where((p) => p['isVideo'] == true).isEmpty
                                ? _buildEmptyState('No reels yet', Icons.video_library)
                                : GridView.builder(
                              padding: const EdgeInsets.all(2),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemCount: _userPosts.where((p) => p['isVideo'] == true).length,
                              itemBuilder: (context, index) => _buildPostThumbnail(
                                _userPosts.where((p) => p['isVideo'] == true).toList()[index],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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