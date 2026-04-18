import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/home/other_user_profile_screen.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _listenToRealTimeRequests();
  }

  void _listenToRealTimeRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('follow_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('follow_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        final requesterId = doc.id;
        final userDoc = await _firestore.collection('users').doc(requesterId).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          requests.add({
            'id': requesterId,
            'name': data['name'] ?? 'User',
            'username': data['username'] ?? 'user',
            'profile_pic': data['profile_pic'] ?? '',
            'bio': data['bio'] ?? '',
            'requestId': doc.id,
            'followers_count': data['followers_count'] ?? 0,
            'posts_count': data['posts_count'] ?? 0,
          });
        }
      }

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String requesterId, String requestId) async {
    if (_processingIds.contains(requestId)) return;

    setState(() {
      _processingIds.add(requestId);
    });

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('follow_requests')
          .doc(requestId)
          .update({'status': 'accepted', 'processedAt': FieldValue.serverTimestamp()});

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .doc(requesterId)
          .set({'followedAt': FieldValue.serverTimestamp()});

      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('following')
          .doc(currentUserId)
          .set({'followedAt': FieldValue.serverTimestamp()});

      await _firestore.collection('users').doc(currentUserId).update({
        'followers_count': FieldValue.increment(1),
      });
      await _firestore.collection('users').doc(requesterId).update({
        'following_count': FieldValue.increment(1),
      });

      setState(() {
        _requests.removeWhere((r) => r['id'] == requesterId);
        _processingIds.remove(requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted! They are now following you.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processingIds.remove(requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    if (_processingIds.contains(requestId)) return;

    setState(() {
      _processingIds.add(requestId);
    });

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('follow_requests')
          .doc(requestId)
          .update({'status': 'rejected', 'processedAt': FieldValue.serverTimestamp()});

      setState(() {
        _requests.removeWhere((r) => r['requestId'] == requestId);
        _processingIds.remove(requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processingIds.remove(requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      appBar: AppBar(
        // ✅ BACK BUTTON - Automatically appears, but explicitly added
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.textMain),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'Follow Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textMain,
        actions: [
          if (_requests.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Accept All?'),
                    content: Text('Accept all ${_requests.length} follow requests?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          for (var request in _requests) {
                            _acceptRequest(request['id'], request['requestId']);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Accept All'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Accept All'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? _buildEmptyState(isDarkMode)
          : RefreshIndicator(
        onRefresh: _loadRequests,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final request = _requests[index];
            final isProcessing = _processingIds.contains(request['requestId']);
            return _buildRequestCard(request, isDarkMode, isProcessing);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_disabled,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'When someone follows you,\nit will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isDarkMode, bool isProcessing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherUserProfileScreen(
                  userId: request['id'],
                  userName: request['name'],
                  userAvatar: request['profile_pic'] ?? '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: request['profile_pic'] != null && request['profile_pic'].isNotEmpty
                        ? NetworkImage(request['profile_pic'])
                        : null,
                    child: request['profile_pic'] == null || request['profile_pic'].isEmpty
                        ? Text(
                      request['name'][0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '@${request['username']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (request['bio'].isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          request['bio'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          _buildStatChip('${request['posts_count']} posts', isDarkMode),
                          const SizedBox(width: 8),
                          _buildStatChip('${request['followers_count']} followers', isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Column(
                  children: [
                    if (isProcessing)
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _acceptRequest(request['id'], request['requestId']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(70, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Accept', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _rejectRequest(request['requestId']),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(70, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}