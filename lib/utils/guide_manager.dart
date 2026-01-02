import 'package:shared_preferences/shared_preferences.dart';

/// Utility class to manage onboarding guide state using SharedPreferences
class GuideManager {
  static const String _keyGuideCompleted = 'onboarding_guide_completed';
  static const String _keyGuideVersion = 'onboarding_guide_version';
  static const int _currentGuideVersion = 1;

  /// Check if the user has completed the onboarding guide
  static Future<bool> hasCompletedGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_keyGuideCompleted) ?? false;
      final version = prefs.getInt(_keyGuideVersion) ?? 0;
      
      // Reset guide if version changed (useful for updates)
      if (version < _currentGuideVersion) {
        await resetGuide();
        return false;
      }
      
      return completed;
    } catch (e) {
      return false;
    }
  }

  /// Mark the guide as completed
  static Future<void> completeGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGuideCompleted, true);
      await prefs.setInt(_keyGuideVersion, _currentGuideVersion);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Reset the guide completion status (for "Take Tour Again" functionality)
  static Future<void> resetGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGuideCompleted, false);
      await prefs.setInt(_keyGuideVersion, _currentGuideVersion);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get the current guide version
  static int get currentVersion => _currentGuideVersion;
}




