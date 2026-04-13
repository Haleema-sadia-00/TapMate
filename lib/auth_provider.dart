// lib/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  bool _isGuest = false;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  String _userId = '';
  bool _isNewSignUp = false;
  String _userEmail = '';
  String _userName = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isGuest => _isGuest;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get canAccessFullFeatures => _isLoggedIn && !_isGuest;
  String get userId => _isGuest ? 'guest' : _userId.isNotEmpty ? _userId : 'unknown';
  bool get isNewSignUp => _isNewSignUp;
  String get userEmail => _userEmail;
  String get userName => _userName;

  AuthProvider() {
    _loadAuthState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;
        _userEmail = user.email ?? '';
        _userName = user.displayName ?? '';
        _isLoggedIn = true;
        _isGuest = false;

        // Check if user is new (hasn't completed onboarding/permissions)
        await _checkIfNewUser(user.uid);

        notifyListeners();
      }
    } catch (e) {
      print('Error checking current user: $e');
    }
  }

  Future<void> _checkIfNewUser(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _isNewSignUp = data['isNewUser'] ?? false;
      }
    } catch (e) {
      print('Error checking if new user: $e');
    }
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('is_guest') ?? false;
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      _userId = prefs.getString('user_id') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _userName = prefs.getString('user_name') ?? '';
      _isNewSignUp = prefs.getBool('is_new_signup') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading auth state: $e');
    }
  }

  Future<void> _persistAuthStateFromUser(
      User user, {
        required bool isNewSignUp,
        String? fallbackName,
        String? fallbackEmail,
      }) async {
    _userId = user.uid;
    _userEmail = user.email ?? fallbackEmail ?? '';
    _userName = user.displayName ?? fallbackName ?? '';
    _isLoggedIn = true;
    _isGuest = false;
    _isNewSignUp = isNewSignUp;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', false);
    await prefs.setString('user_id', _userId);
    await prefs.setString('user_email', _userEmail);
    await prefs.setString('user_name', _userName);
    await prefs.setBool('is_new_signup', isNewSignUp);

    notifyListeners();
  }

  // 🔥 CHECK IF USERNAME EXISTS
  Future<bool> checkUsernameExists(String username) async {
    try {
      if (username.isEmpty) return false;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // 🔥 GET SAVED EMAIL (REMEMBER ME)
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_email');
    } catch (e) {
      print('Error getting saved email: $e');
      return null;
    }
  }

  // 🔥 SAVE USER EMAIL
  Future<void> saveUserEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email.trim());
    } catch (e) {
      print('Error saving email: $e');
    }
  }

  // 🔥 CLEAR SAVED EMAIL
  Future<void> clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
    } catch (e) {
      print('Error clearing saved email: $e');
    }
  }

  // 🔥 CHECK IF NEEDS PERMISSION SCREEN
  Future<bool> needsPermissionScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool hasCompletedPermissions = prefs.getBool('has_completed_permissions') ?? false;
      return !hasCompletedPermissions && _isNewSignUp;
    } catch (e) {
      print('Error checking permission screen: $e');
      return false;
    }
  }

  // 🔥 FIREBASE LOGIN METHOD
  Future<Map<String, dynamic>> loginWithEmailPassword(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Email and password are required'};
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        return {'success': false, 'message': 'Login failed. Please try again.'};
      }

      _userId = result.user!.uid;
      _userEmail = result.user!.email ?? email.trim();
      _userName = result.user!.displayName ?? '';
      _isLoggedIn = true;
      _isGuest = false;
      _isNewSignUp = false;

      // Check if user exists in Firestore
      bool isNewUser = false;
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          isNewUser = data['isNewUser'] ?? false;

          // Update login info
          await _firestore.collection('users').doc(_userId).update({
            'lastLogin': FieldValue.serverTimestamp(),
            'loginCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create user document if not exists
          await _firestore.collection('users').doc(_userId).set({
            'name': _userName.isNotEmpty ? _userName : email.split('@').first,
            'email': _userEmail,
            'username': email.split('@').first.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'loginCount': 1,
            'isNewUser': false,
            'emailVerified': result.user!.emailVerified,
          });
          isNewUser = true;
        }
      } catch (e) {
        print('Firestore error during login: $e');
        // Continue even if Firestore fails - user is still authenticated
      }

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_guest', false);
        await prefs.setString('user_id', _userId);
        await prefs.setString('user_email', _userEmail);
        await prefs.setString('user_name', _userName);
        await prefs.setBool('is_new_signup', isNewUser);
      } catch (e) {
        print('Error saving to SharedPreferences: $e');
      }

      notifyListeners();

      return {
        'success': true,
        'message': 'Login successful!',
        'isNewUser': isNewUser
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email. Please sign up first.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return {'success': false, 'message': message};
    } catch (e) {
      final errorText = e.toString();
      print('Login error: $errorText');

      if (errorText.contains('PigeonUserDetails')) {
        final fallbackUser = _auth.currentUser;
        if (fallbackUser != null) {
          try {
            await _persistAuthStateFromUser(
              fallbackUser,
              isNewSignUp: false,
              fallbackEmail: email.trim(),
            );
            return {
              'success': true,
              'message': 'Login successful!',
              'isRecoveredFromPluginMismatch': true,
            };
          } catch (persistError) {
            print('Login recovery persistence error: $persistError');
          }
        }

        return {
          'success': false,
          'message':
          'Login plugin mismatch detected. Please fully restart the app (not hot reload) after running flutter clean and flutter pub get.',
        };
      }

      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // 🔥 FIREBASE SIGNUP METHOD - FIXED
  Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
    DateTime? dob,
    String? gender,
    String? username, required String recoveryEmail,
  }) async {
    try {
      // Validate required fields
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'All required fields must be filled'};
      }

      // Create user in Firebase Auth
      UserCredential result;
      try {
        result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } catch (e) {
        print('Error creating user: $e');
        rethrow;
      }

      if (result.user == null) {
        return {'success': false, 'message': 'Failed to create account'};
      }

      // Update display name
      try {
        await result.user!.updateDisplayName(name);
        await result.user!.reload();
      } catch (e) {
        print('Error updating display name: $e');
        // Continue even if display name update fails
      }

      // Send email verification
      try {
        await result.user!.sendEmailVerification();
      } catch (e) {
        print('Error sending verification email: $e');
        // Continue even if verification email fails
      }

      // Prepare user data for Firestore
      Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'username': username?.toLowerCase().trim() ??
            name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'isNewUser': true,
        'loginCount': 1,
      };

      // Add optional fields only if they're provided and not empty
      if (phone != null && phone.trim().isNotEmpty) {
        userData['phone'] = phone.trim();
      }

      if (dob != null) {
        userData['dob'] = dob.toIso8601String();
      }

      if (gender != null && gender.trim().isNotEmpty) {
        userData['gender'] = gender.trim();
      }

      // Save to Firestore
      try {
        await _firestore.collection('users').doc(result.user!.uid).set(userData);
      } catch (e) {
        print('Error saving to Firestore: $e');
        // Continue even if Firestore fails - user is still authenticated
      }

      // Update local state
      _userId = result.user!.uid;
      _userEmail = result.user!.email ?? email.trim();
      _userName = name.trim();
      _isLoggedIn = true;
      _isGuest = false;
      _isNewSignUp = true;

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_guest', false);
        await prefs.setString('user_id', _userId);
        await prefs.setString('user_email', _userEmail);
        await prefs.setString('user_name', _userName);
        await prefs.setBool('is_new_signup', true);
      } catch (e) {
        print('Error saving to SharedPreferences: $e');
      }

      notifyListeners();

      return {
        'success': true,
        'message': 'Account created! Please verify your email.'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please login.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use 8+ chars with letters and numbers.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password sign up is not enabled.';
      }
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return {'success': false, 'message': message};
    } catch (e) {
      final errorText = e.toString();
      print('Signup error: $errorText');

      if (errorText.contains('PigeonUserDetails')) {
        final fallbackUser = _auth.currentUser;
        if (fallbackUser != null) {
          try {
            await _persistAuthStateFromUser(
              fallbackUser,
              isNewSignUp: true,
              fallbackName: name.trim(),
              fallbackEmail: email.trim(),
            );

            // Ensure user profile exists for recovered signups.
            await _firestore.collection('users').doc(fallbackUser.uid).set({
              'name': fallbackUser.displayName?.isNotEmpty == true
                  ? fallbackUser.displayName
                  : name.trim(),
              'email': fallbackUser.email ?? email.trim().toLowerCase(),
              'username': username?.toLowerCase().trim() ??
                  name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
              'createdAt': FieldValue.serverTimestamp(),
              'emailVerified': fallbackUser.emailVerified,
              'isNewUser': true,
              'loginCount': 1,
            }, SetOptions(merge: true));

            return {
              'success': true,
              'message': 'Account created! Please verify your email.',
              'isRecoveredFromPluginMismatch': true,
            };
          } catch (recoverError) {
            print('Signup recovery error: $recoverError');
          }
        }

        return {
          'success': false,
          'message':
          'Signup plugin mismatch detected. Please fully restart the app (not hot reload) after running flutter clean and flutter pub get.',
        };
      }

      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // 🔥 GOOGLE SIGN IN
// 🔥 ACTUAL GOOGLE SIGN IN IMPLEMENTATION
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Sign in aborted by user'};
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user == null) {
        return {'success': false, 'message': 'Firebase sign in failed'};
      }

      _userId = user.uid;
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? '';
      _isLoggedIn = true;
      _isGuest = false;

      // 5. Check Firestore and update/create user
      bool isNewUser = false;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists) {
        isNewUser = true;
        await _firestore.collection('users').doc(_userId).set({
          'name': _userName,
          'email': _userEmail,
          'username': _userEmail.split('@').first.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'isNewUser': true,
          'loginCount': 1,
          'provider': 'google',
        });
      } else {
        await _firestore.collection('users').doc(_userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'loginCount': FieldValue.increment(1),
        });
      }

      _isNewSignUp = isNewUser;

      // 6. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_name', _userName);
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setBool('is_new_signup', isNewUser);

      notifyListeners();

      return {
        'success': true,
        'message': 'Google sign in successful',
        'isNewUser': isNewUser
      };
    } catch (e) {
      print('Google sign in error: $e');
      return {'success': false, 'message': 'Google sign in failed: ${e.toString()}'};
    }
  }
  // 🔥 FACEBOOK SIGN IN
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      // TODO: Implement actual Facebook Sign In
      await Future.delayed(const Duration(seconds: 1));

      String mockUid = 'facebook_${DateTime.now().millisecondsSinceEpoch}';
      bool isNewUser = true;

      _userId = mockUid;
      _userEmail = 'user@facebook.com';
      _userName = 'Facebook User';
      _isLoggedIn = true;
      _isGuest = false;
      _isNewSignUp = isNewUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_name', _userName);
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setBool('is_new_signup', isNewUser);

      notifyListeners();

      return {
        'success': true,
        'message': 'Facebook sign in successful',
        'isNewUser': isNewUser
      };
    } catch (e) {
      print('Facebook sign in error: $e');
      return {'success': false, 'message': 'Facebook sign in failed'};
    }
  }

  // 🔥 SOCIAL LOGIN (General)
  Future<void> socialLogin(String platform) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      _userId = 'social_${platform.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
      _userEmail = 'user@$platform.com';
      _userName = platform;
      _isLoggedIn = true;
      _isGuest = false;
      _isNewSignUp = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_name', _userName);
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setBool('is_new_signup', true);

      notifyListeners();
    } catch (e) {
      print('Social login error: $e');
    }
  }

  // 🔥 VERIFY EMAIL
  Future<Map<String, dynamic>> verifyEmail(String otp) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      await user.reload();
      user = _auth.currentUser;

      if (user?.emailVerified == true) {
        try {
          await _firestore.collection('users').doc(user!.uid).update({
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
            'isNewUser': false,
          });
        } catch (e) {
          print('Error updating email verified status: $e');
        }

        // Clear new signup flag
        _isNewSignUp = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_new_signup', false);

        return {'success': true, 'message': 'Email verified successfully!'};
      } else {
        return {'success': false, 'message': 'Email not verified yet'};
      }
    } catch (e) {
      print('Email verification error: $e');
      return {'success': false, 'message': 'Verification failed. Please try again.'};
    }
  }

  // 🔥 RESEND VERIFICATION EMAIL
  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        return {'success': true, 'message': 'Verification email sent!'};
      }
      return {'success': false, 'message': 'No user logged in'};
    } catch (e) {
      print('Resend OTP error: $e');
      return {'success': false, 'message': 'Failed to resend verification email'};
    }
  }

  // 🔥 SET USER INFO
  Future<void> setUserInfo({required String userId, required String email, String? name}) async {
    try {
      _userId = userId;
      _userEmail = email;
      _userName = name ?? '';
      _isGuest = false;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', email);
      if (name != null) await prefs.setString('user_name', name);
      await prefs.setBool('is_guest', false);
      await prefs.setBool('is_logged_in', true);

      notifyListeners();
    } catch (e) {
      print('Error setting user info: $e');
    }
  }

  // 🔥 MARK AS NEW SIGNUP
  Future<void> markAsNewSignUp() async {
    try {
      _isNewSignUp = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_new_signup', true);
      notifyListeners();
    } catch (e) {
      print('Error marking as new signup: $e');
    }
  }

  // 🔥 CLEAR NEW SIGNUP FLAG
  Future<void> clearNewSignUpFlag() async {
    try {
      _isNewSignUp = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_new_signup', false);

      // Also update Firestore
      if (_userId.isNotEmpty && _userId != 'guest') {
        try {
          await _firestore.collection('users').doc(_userId).update({
            'isNewUser': false,
          });
        } catch (e) {
          print('Error updating isNewUser in Firestore: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error clearing new signup flag: $e');
    }
  }

  // 🔥 SET LOGGED IN
  Future<void> setLoggedIn(bool loggedIn) async {
    try {
      _isLoggedIn = loggedIn;
      _isGuest = !loggedIn;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', loggedIn);
      await prefs.setBool('is_guest', !loggedIn);

      if (!loggedIn) {
        _userId = '';
        _userEmail = '';
        _userName = '';
        await prefs.setString('user_id', '');
        await prefs.setString('user_email', '');
        await prefs.setString('user_name', '');
      }

      notifyListeners();
    } catch (e) {
      print('Error setting logged in: $e');
    }
  }

  // 🔥 LOGOUT
  Future<void> logout() async {
    try {
      await _auth.signOut();

      _isGuest = false;
      _isLoggedIn = false;
      _userId = '';
      _userEmail = '';
      _userName = '';
      _isNewSignUp = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // 🔥 RESET PASSWORD
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return {'success': false, 'message': 'Email is required'};
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true, 'message': 'Password reset email sent!'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'No account found with this email'};
      } else if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Invalid email address'};
      }
      print('Reset password error: $e');
      return {'success': false, 'message': 'Failed to send reset email'};
    } catch (e) {
      print('Reset password error: $e');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  // 🔥 GUEST MODE
  Future<void> setGuestMode(bool isGuest) async {
    try {
      _isGuest = isGuest;
      _isLoggedIn = !isGuest;
      _userId = isGuest ? 'guest' : '';
      _userEmail = '';
      _userName = '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', isGuest);
      await prefs.setBool('is_logged_in', !isGuest);
      await prefs.setString('user_id', isGuest ? 'guest' : '');
      await prefs.setString('user_email', '');
      await prefs.setString('user_name', '');

      if (isGuest) {
        _isNewSignUp = false;
        await prefs.setBool('is_new_signup', false);
      }
      notifyListeners();
    } catch (e) {
      print('Error setting guest mode: $e');
    }
  }

  // 🔥 SET ONBOARDING COMPLETED
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      _hasCompletedOnboarding = completed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', completed);
      notifyListeners();
    } catch (e) {
      print('Error setting onboarding completed: $e');
    }
  }

  // 🔥 SET PERMISSIONS COMPLETED
  Future<void> setPermissionsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_permissions', true);

      // Clear new signup flag if needed
      if (_isNewSignUp) {
        _isNewSignUp = false;
        await prefs.setBool('is_new_signup', false);

        // Update Firestore
        if (_userId.isNotEmpty && _userId != 'guest') {
          try {
            await _firestore.collection('users').doc(_userId).update({
              'isNewUser': false,
              'permissionsCompleted': true,
              'permissionsCompletedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            print('Error updating permissions completed in Firestore: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error setting permissions completed: $e');
    }
  }

  // 🔥 GENERATE USER ID FROM EMAIL
  static String generateUserIdFromEmail(String email) {
    if (email.isEmpty) return 'unknown';
    return email.split('@').first + '_' + DateTime.now().millisecondsSinceEpoch.toString();
  }

  // 🔥 HAS USER DATA
  Future<bool> hasUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id')?.isNotEmpty ?? false;
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }

  // 🔥 GET USER DATA FROM FIRESTORE
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // 🔥 UPDATE USER DATA
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_userId.isEmpty || _userId == 'guest') {
        return false;
      }

      await _firestore.collection('users').doc(_userId).update(data);
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }
}