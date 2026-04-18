import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:share_plus/share_plus.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'package:tapmate/Screen/home/create_post_screen.dart';
import 'package:tapmate/Screen/home/edit_profile_screen.dart';
import 'package:tapmate/Screen/home/post_detail_screen.dart';
import 'package:tapmate/Screen/home/saved_posts_screen.dart';
import 'package:tapmate/Screen/home/followers_screen.dart';
import 'package:tapmate/Screen/home/following_screen.dart';
import 'package:tapmate/Screen/home/other_user_profile_screen.dart';
import 'package:tapmate/Screen/home/follow_requests_screen.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/auth_provider.dart' as myAuth;
import 'package:tapmate/theme_provider.dart';
import 'package:tapmate/Screen/services/follow_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Data variables
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _savedPosts = [];

  // Counts
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  int _pendingRequestsCount = 0;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FollowService _followService = FollowService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _listenToPendingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _listenToPendingRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('follow_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _pendingRequestsCount = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'No user logged in';
        });
        return;
      }

      print('📱 Loading user data for: ${currentUser.uid}');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>? ?? {};

        // FETCH FOLLOWERS FROM SUBCOLLECTION
        final followersSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('followers')
            .get();

        final List<String> followersList = followersSnapshot.docs.map((doc) => doc.id).toList();

        // FETCH FOLLOWING FROM SUBCOLLECTION
        final followingSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('following')
            .get();

        final List<String> followingList = followingSnapshot.docs.map((doc) => doc.id).toList();

        setState(() {
          _userData = {
            'id': currentUser.uid,
            'email': currentUser.email ?? '',
            'name': data['name'] ?? currentUser.displayName ?? 'User',
            'username': data['username'] ?? currentUser.email?.split('@').first ?? 'user',
            'bio': data['bio'] ?? 'No bio added yet',
            'profile_pic': data['profile_pic'] ?? '',
            'phone': data['phone'] ?? '',
            'website': data['website'] ?? '',
            'gender': data['gender'] ?? '',
            'posts_count': data['posts_count'] ?? 0,
            'followers_count': followersList.length,
            'following_count': followingList.length,
            'followers': followersList,
            'following': followingList,
            'is_private': data['is_private'] ?? false,
            'createdAt': data['createdAt'],
          };

          _postsCount = _userData['posts_count'];
          _followersCount = followersList.length;
          _followingCount = followingList.length;
        });

        print('✅ User data loaded');
        print('📊 Followers (${followersList.length}): $followersList');
        print('📊 Following (${followingList.length}): $followingList');

        await _loadUserPosts(currentUser.uid);
        await _loadSavedPosts(currentUser.uid);
      } else {
        print('User document not found, creating...');
        await _createUserDocument(currentUser);
        await _loadUserData();
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _error = 'Failed to load profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      Map<String, dynamic> userData = {
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'username': user.email?.split('@').first ?? 'user',
        'bio': 'No bio added yet',
        'profile_pic': '',
        'phone': '',
        'website': '',
        'gender': '',
        'posts_count': 0,
        'followers_count': 0,
        'following_count': 0,
        'is_private': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      // Initialize empty subcollections
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .doc('_init')
          .set({'_': true}, SetOptions(merge: true));
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc('_init')
          .set({'_': true}, SetOptions(merge: true));
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('follow_requests')
          .doc('_init')
          .set({'_': true}, SetOptions(merge: true));

      // Delete init docs
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .doc('_init')
          .delete();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc('_init')
          .delete();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('follow_requests')
          .doc('_init')
          .delete();

      print('✅ User document created with subcollections');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  Future<void> _openFollowersScreen() async {
    if (_userData['followers'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No followers yet'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> followersList = [];

    for (String uid in _userData['followers']) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
        followersList.add({
          'id': uid,
          'name': data['name'] ?? 'User',
          'username': data['username'] ?? 'user',
          'profile_pic': data['profile_pic'] ?? '',
          'bio': data['bio'] ?? '',
        });
      }
    }

    if (mounted) Navigator.pop(context);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowersScreen(
            followers: followersList,
            onUserTap: (user) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfileScreen(
                    userId: user['id'],
                    userName: user['name'],
                    userAvatar: user['profile_pic'] ?? '',
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _openFollowingScreen() async {
    if (_userData['following'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not following anyone yet'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> followingList = [];

    for (String uid in _userData['following']) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
        followingList.add({
          'id': uid,
          'name': data['name'] ?? 'User',
          'username': data['username'] ?? 'user',
          'profile_pic': data['profile_pic'] ?? '',
          'bio': data['bio'] ?? '',
        });
      }
    }

    if (mounted) Navigator.pop(context);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowingScreen(
            following: followingList,
            onUserTap: (user) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfileScreen(
                    userId: user['id'],
                    userName: user['name'],
                    userAvatar: user['profile_pic'] ?? '',
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadUserPosts(String userId) async {
    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _posts = postsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'userId': data['userId'] ?? '',
            'caption': data['caption'] ?? '',
            'thumbnail': data['thumbnailUrl'] ?? '',
            'videoUrl': data['videoUrl'],
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isVideo': data['isVideo'] ?? false,
            'createdAt': data['createdAt'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _loadSavedPosts(String userId) async {
    try {
      QuerySnapshot savedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .orderBy('savedAt', descending: true)
          .get();

      List<Map<String, dynamic>> savedList = [];
      for (var doc in savedSnapshot.docs) {
        String postId = doc['postId'];
        DocumentSnapshot postDoc = await _firestore
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>? ?? {};
          savedList.add({
            'id': postId,
            'userId': postData['userId'] ?? '',
            'title': postData['title'] ?? '',
            'thumbnail': postData['thumbnailUrl'] ?? '',
            'likes': postData['likes'] ?? 0,
            'comments': postData['comments'] ?? 0,
          });
        }
      }

      setState(() {
        _savedPosts = savedList;
      });
    } catch (e) {
      print('Error loading saved posts: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<myAuth.AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
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
          border: Border.all(color: Colors.white, width: 3),
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
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar();
            },
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
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostThumbnail(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: post['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post['thumbnail'] != null && post['thumbnail'].toString().isNotEmpty)
              Image.network(
                post['thumbnail'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
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
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(post['comments'] ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            if (post['isVideo'] == true)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
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
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Follow Requests Option with Badge
            ListTile(
              leading: const Icon(Icons.person_add, color: AppColors.primary),
              title: const Text('Follow Requests'),
              subtitle: Text(_pendingRequestsCount > 0 ? '$_pendingRequestsCount pending requests' : 'No pending requests'),
              trailing: _pendingRequestsCount > 0
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pendingRequestsCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FollowRequestsScreen()),
                ).then((_) => _loadUserData());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Profile'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: _userData),
                  ),
                );
                if (result != null && result['success'] == true) {
                  await _loadUserData();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: AppColors.primary),
              title: const Text('Saved Posts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedPostsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareProfile() {
    final String userName = _userData['name'] ?? 'User';
    final String username = _userData['username'] ?? 'user';
    final String userId = _userData['id'] ?? '';

    final String shareText = '''
Check out $userName's profile on TapMate! 👤

Username: @$username
Bio: ${_userData['bio'] ?? 'No bio yet'}

Followers: $_followersCount
Posts: $_postsCount

Follow them on TapMate to see their content!
''';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2C2C)
          : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link, 'Copy Link', () async {
                  Navigator.pop(context);
                  final String profileLink = 'tapmate://user/$userId';
                  await Clipboard.setData(ClipboardData(text: profileLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile link copied!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }),
                _buildShareOption(Icons.share, 'Share', () async {
                  Navigator.pop(context);
                  await Share.share(shareText);
                }),
                _buildShareOption(Icons.qr_code, 'QR Code', () {
                  Navigator.pop(context);
                  _showQRCode();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.qr_code, size: 100, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '@${_userData['username'] ?? 'user'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<myAuth.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGuest = authProvider.isGuest;
    final isDarkMode = themeProvider.isDarkMode;

    if (isGuest) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 80, color: AppColors.primary),
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
                    'Please sign in to access your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadUserData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ CLEAN HEADER - Only back, title, refresh, 3 dots
// Header mein - 3 dots ki jagah ye rakho
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
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // ✅ FOLLOW REQUESTS ICON WITH BADGE
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FollowRequestsScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      if (_pendingRequestsCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              _pendingRequestsCount > 9 ? '9+' : '$_pendingRequestsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _loadUserData();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: _showProfileOptions,
                  ),
                ],
              ),
            ),
            // Rest of the UI
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _buildProfilePicture(),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn('Posts', _formatNumber(_postsCount), () => _tabController.animateTo(0)),
                                    _buildStatColumn('Followers', _formatNumber(_followersCount), _openFollowersScreen),
                                    _buildStatColumn('Following', _formatNumber(_followingCount), _openFollowingScreen),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          // ✅ Name with Private Account Lock
                          Row(
                            children: [
                              Text(
                                _userData['name'] ?? 'Your Name',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppColors.accent,
                                ),
                              ),
                              if (_userData['is_private'] == true) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.lock, size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '@${_userData['username'] ?? 'username'}',
                              style: TextStyle(fontSize: 14, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_userData['bio'] != null && _userData['bio'].isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _userData['bio'] ?? 'No bio added yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[300] : AppColors.textMain,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (_userData['phone'] != null && _userData['phone'].isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Text(
                                    _userData['phone']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey[300] : AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_userData['website'] != null && _userData['website'].isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(Icons.link, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _userData['website']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey[300] : AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_userData['gender'] != null && _userData['gender'].isNotEmpty && _userData['gender'] != 'Prefer not to say')
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const SizedBox(width: 6),
                                  Text(
                                    _userData['gender']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey[300] : AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(userData: _userData),
                                      ),
                                    );
                                    if (result != null && result['success'] == true) {
                                      await _loadUserData();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _showShareProfile,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Icon(Icons.share, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1)),
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
                          Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _posts.isEmpty
                              ? _buildEmptyState('No posts yet', Icons.photo_library)
                              : GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) => _buildPostThumbnail(_posts[index]),
                          ),
                          _posts.where((p) => p['isVideo'] == true).isEmpty
                              ? _buildEmptyState('No reels yet', Icons.video_library)
                              : GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: _posts.where((p) => p['isVideo'] == true).length,
                            itemBuilder: (context, index) => _buildPostThumbnail(
                              _posts.where((p) => p['isVideo'] == true).toList()[index],
                            ),
                          ),
                          _savedPosts.isEmpty
                              ? _buildEmptyState('No saved posts', Icons.bookmark_border)
                              : GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: _savedPosts.length,
                            itemBuilder: (context, index) => _buildPostThumbnail(_savedPosts[index]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreatePostScreen()),
                    );
                    _loadUserData();
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  label: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', false),
                  _buildNavItem(Icons.search, 'Search', false),
                  _buildNavItem(Icons.feed_rounded, 'Feed', false),
                  _buildNavItem(Icons.message_rounded, 'Message', false),
                  _buildNavItem(Icons.person_rounded, 'Profile', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive ? AppColors.primary : (isDark ? Colors.grey[600] : Colors.grey);

    return GestureDetector(
      onTap: () {
        if (label == 'Home') Navigator.pushReplacementNamed(context, '/home');
        else if (label == 'Search') Navigator.pushReplacementNamed(context, '/search');
        else if (label == 'Feed') Navigator.pushReplacementNamed(context, '/feed');
        else if (label == 'Message') Navigator.pushReplacementNamed(context, '/chat');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}