// lib/services/follow_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Follow a user
  Future<void> followUser(String targetUserId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not logged in');

    final batch = _firestore.batch();

    // Add to current user's following
    DocumentReference followingRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUserId);

    batch.set(followingRef, {
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Add to target user's followers
    DocumentReference followersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUser.uid);

    batch.set(followersRef, {
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Update counts
    batch.update(
      _firestore.collection('users').doc(currentUser.uid),
      {'following_count': FieldValue.increment(1)},
    );

    batch.update(
      _firestore.collection('users').doc(targetUserId),
      {'followers_count': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not logged in');

    final batch = _firestore.batch();

    // Remove from following
    batch.delete(
      _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId),
    );

    // Remove from followers
    batch.delete(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid),
    );

    // Update counts
    batch.update(
      _firestore.collection('users').doc(currentUser.uid),
      {'following_count': FieldValue.increment(-1)},
    );

    batch.update(
      _firestore.collection('users').doc(targetUserId),
      {'followers_count': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  // Check if following
  Future<bool> isFollowing(String targetUserId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }
  // lib/Screen/services/follow_service.dart mein add karo

// Block a user
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // First, unfollow if following
      if (await isFollowing(userId)) {
        await unfollowUser(userId);
      }

      // Add to blocked list
      await _firestore.collection('users').doc(currentUser.uid).update({
        'blockedUsers': FieldValue.arrayUnion([userId]),
      });

      // Also remove from followers if they were following you
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('followers')
          .doc(userId)
          .delete();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(currentUser.uid)
          .delete();

      print('✅ User blocked: $userId');
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

// Unblock a user
  Future<void> unblockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'blockedUsers': FieldValue.arrayRemove([userId]),
      });
      print('✅ User unblocked: $userId');
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      final blockedUsers = List<String>.from(data['blockedUsers'] ?? []);
      return blockedUsers.contains(userId);
    } catch (e) {
      print('Error checking block status: $e');
      return false;
    }
  }

// Get blocked users list
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>;
      final blockedUsersIds = List<String>.from(data['blockedUsers'] ?? []);

      List<Map<String, dynamic>> blockedUsers = [];

      for (String uid in blockedUsersIds) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          blockedUsers.add({
            'uid': uid,
            'fullName': userData['name'] ?? 'Unknown',
            'username': userData['username'] ?? 'user',
            'profilePic': userData['profile_pic'] ?? '',
            'blockedAt': DateTime.now(),
          });
        }
      }

      return blockedUsers;
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }
}