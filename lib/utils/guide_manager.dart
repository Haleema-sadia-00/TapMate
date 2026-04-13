import 'package:shared_preferences/shared_preferences.dart';

class GuideManager {
  static const String _globalGuideKey = 'onboarding_guide_completed';
  static const String _globalGuideVersionKey = 'onboarding_guide_version';
  static const int _currentGuideVersion = 1;

  // 🔥 FIX: \$userId ki jagah $userId
  static String _userGuideKey(String userId) => 'guide_completed_$userId';
  static String _userFirstTimeKey(String userId) => 'first_time_user_$userId';
  static String _firstDownloadShownKey(String userId) => 'first_download_shown_$userId';

  // ================== USER-SCOPED METHODS ==================
  static Future<bool> hasUserCompletedGuide(String userId) async {
    if (userId.isEmpty || userId == 'guest') {
      print('⚠️ hasUserCompletedGuide: userId empty or guest');
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_userGuideKey(userId)) ?? false;
    print('📚 User $userId - Guide completed: $completed');
    return completed;
  }

  static Future<void> completeGuideForUser(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userGuideKey(userId), true);
    await prefs.setBool(_userFirstTimeKey(userId), false);
    print('✅ Guide completed for user: $userId');
  }

  static Future<void> resetGuideForUser(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userGuideKey(userId), false);
    await prefs.setBool(_userFirstTimeKey(userId), true);
    print('🔄 Guide reset for user: $userId');
  }

  static Future<bool> isFirstTimeUser(String userId) async {
    if (userId.isEmpty || userId == 'guest') return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userFirstTimeKey(userId)) ?? true;
  }

  static Future<void> markUserAsReturning(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userFirstTimeKey(userId), false);
  }

  static Future<bool> shouldShowGuide({
    required String userId,
    required bool isGuest,
    bool isNewSignUp = false,
  }) async {
    if (isGuest) return false;
    if (isNewSignUp) return true;
    final completed = await hasUserCompletedGuide(userId);
    return !completed;
  }

  // ================== First-download celebratory flag ==================
  static Future<bool> hasShownFirstDownload(String userId) async {
    if (userId.isEmpty || userId == 'guest') return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstDownloadShownKey(userId)) ?? false;
  }

  static Future<void> markFirstDownloadShown(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstDownloadShownKey(userId), true);
  }
}