// lib/utils/guide_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class GuideManager {
  static const String _guideCompletedKey = 'guide_completed';

  static Future<bool> hasCompletedGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guideCompletedKey) ?? false;
  }

  static Future<void> completeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guideCompletedKey, true);
  }

  static Future<void> resetGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guideCompletedKey, false);
  }
}