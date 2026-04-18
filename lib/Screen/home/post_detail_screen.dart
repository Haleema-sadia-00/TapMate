import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/home/other_user_profile_screen.dart';
import 'package:tapmate/Screen/home/comments_screen.dart';
import 'package:tapmate/Screen/home/video_player_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isLiked = false;
  bool _isSaving = false;
  bool _isSaved = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  Map<String, dynamic> _postData = {};
  Map<String, dynamic> _userData = {};

  late AnimationController _animationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _loadPostData();
    _checkIfSaved();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final savedDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(widget.postId)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = savedDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking saved: $e');
    }
  }

  Future<void> _loadPostData() async {
    setState(() => _isLoading = true);

    try {
      print('📥 Loading post: ${widget.postId}');

      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      _postData = postDoc.data() as Map<String, dynamic>;
      _likesCount = _postData['likes'] ?? 0;
      _commentsCount = _postData['comments'] ?? 0;

      print('✅ Post loaded - Likes: $_likesCount, Comments: $_commentsCount');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_postData['userId'])
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        DocumentSnapshot likeDoc = await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .doc(currentUserId)
            .get();

        _isLiked = likeDoc.exists;
      }

    } catch (e) {
      print('❌ Error loading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    // Animate like
    if (!_isLiked) {
      _animationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 300), () {
        _animationController.reset();
      });
    }

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .doc(userId)
            .set({
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('posts').doc(widget.postId).update({
          'likes': FieldValue.increment(1),
        });
      } else {
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .doc(userId)
            .delete();
        await _firestore.collection('posts').doc(widget.postId).update({
          'likes': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleSave() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isSaved) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_posts')
            .doc(widget.postId)
            .delete();

        setState(() => _isSaved = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post removed from saved'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_posts')
            .doc(widget.postId)
            .set({
          'postId': widget.postId,
          'savedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isSaved = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post saved to collection'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login to interact with posts'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: widget.postId,
          contentTitle: _postData['caption'] ?? 'Post',
          initialCommentCount: _commentsCount,
        ),
      ),
    ).then((_) => _loadPostData()); // Refresh after returning
  }

  // ✅ REAL-TIME SHARE FUNCTIONALITY
  Future<void> _sharePost() async {
    final String postUrl = 'tapmate://post/${widget.postId}';
    final String caption = _postData['caption'] ?? 'Check out this post on TapMate!';
    final String userName = _userData['name'] ?? 'User';

    try {
      await Share.share(
        '$caption\n\nShared by $userName on TapMate\n\n$postUrl',
        subject: 'TapMate Post',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share dialog opened!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPostOptions() {
    final isMyPost = _postData['userId'] == _auth.currentUser?.uid;

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
            if (isMyPost) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.orange),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Delete post
        await _firestore.collection('posts').doc(widget.postId).delete();

        // Delete likes subcollection
        final likesSnapshot = await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .get();

        final batch = _firestore.batch();
        for (var doc in likesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          Navigator.pop(context); // Close loading
          Navigator.pop(context, true); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post? Our team will review it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Save report to Firestore
              try {
                await _firestore.collection('reports').add({
                  'postId': widget.postId,
                  'reportedBy': _auth.currentUser?.uid,
                  'reason': 'User reported',
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post reported. Thank you for your feedback!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _viewUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          userId: _postData['userId'],
          userName: _userData['name'] ?? 'User',
          userAvatar: _userData['profile_pic'] ?? '',
        ),
      ),
    );
  }

  void _playVideo() {
    final videoUrl = _postData['videoUrl'];
    if (_postData['isVideo'] == true && videoUrl != null && videoUrl.toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: videoUrl.toString()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL not available'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return 'Recently';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.textMain),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : AppColors.textMain),
                    onPressed: _showPostOptions,
                  ),
                ],
              ),
            ),

            // Post Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    ListTile(
                      leading: GestureDetector(
                        onTap: _viewUserProfile,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: _userData['profile_pic'] != null && _userData['profile_pic'].isNotEmpty
                              ? NetworkImage(_userData['profile_pic'])
                              : null,
                          child: _userData['profile_pic'] == null || _userData['profile_pic'].isEmpty
                              ? Text(
                            (_userData['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                              : null,
                        ),
                      ),
                      title: GestureDetector(
                        onTap: _viewUserProfile,
                        child: Text(
                          _userData['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textMain,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(_postData['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),

                    // Media
                    GestureDetector(
                      onTap: _postData['isVideo'] == true ? _playVideo : null,
                      child: Container(
                        height: 400,
                        width: double.infinity,
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        child: _postData['isVideo'] == true
                            ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              _postData['thumbnailUrl'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 400,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.video_library, size: 50),
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        )
                            : Image.network(
                          _postData['thumbnailUrl'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 400,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Caption
                    if (_postData['caption'] != null && _postData['caption'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _postData['caption'],
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode ? Colors.white : AppColors.textMain,
                            height: 1.4,
                          ),
                        ),
                      ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_formatNumber(_likesCount)} likes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : AppColors.textMain,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '${_formatNumber(_commentsCount)} comments',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Action Buttons
                    // Action Buttons - REPLACE this whole section
                    // Action Buttons - REPLACE with this fixed version
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Like Button - FIXED
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                print('🔴 Like button tapped'); // Debug
                                _toggleLike();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    key: ValueKey(_isLiked),
                                    children: [
                                      Icon(
                                        _isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: _isLiked ? Colors.red : AppColors.primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isLiked ? 'Liked' : 'Like',
                                        style: TextStyle(
                                          color: _isLiked ? Colors.red : AppColors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Comment Button
                          Expanded(
                            child: InkWell(
                              onTap: _openComments,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.comment_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Comment',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Share Button
                          Expanded(
                            child: InkWell(
                              onTap: _sharePost,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
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