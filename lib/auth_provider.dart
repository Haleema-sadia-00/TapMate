import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isGuest = false;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  bool get isGuest => _isGuest;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get canAccessFullFeatures => _isLoggedIn && !_isGuest;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
    notifyListeners();
  }

  Future<void> setGuestMode(bool isGuest) async {
    _isGuest = isGuest;
    _isLoggedIn = !isGuest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', isGuest);
    await prefs.setBool('is_logged_in', !isGuest);
    notifyListeners();
  }

  Future<void> setLoggedIn(bool loggedIn) async {
    _isLoggedIn = loggedIn;
    _isGuest = !loggedIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', loggedIn);
    await prefs.setBool('is_guest', !loggedIn);
    notifyListeners();
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _hasCompletedOnboarding = completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', completed);
    notifyListeners();
  }

  Future<void> logout() async {
    _isGuest = false;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    await prefs.setBool('is_logged_in', false);
    notifyListeners();
  }
}






