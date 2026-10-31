import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _keyUser = 'medihub_cached_user';
  static const String _keyOnboardingCompleted = 'medihub_onboarding_completed';

  final SharedPreferences? prefs;

  LocalStorageService({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  /// Saves the active user model into SharedPreferences
  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await _instance;
      await prefs.setString(_keyUser, jsonEncode(user.toJsonMap()));
      if (user.onboardingStatus == OnboardingStep.completed) {
        await prefs.setBool(_keyOnboardingCompleted, true);
      }
    } catch (_) {}
  }

  /// Retrieves the cached user from SharedPreferences if available
  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(_keyUser);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJsonMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Checks if the onboarding completed flag is set in SharedPreferences
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await _instance;
      return prefs.getBool(_keyOnboardingCompleted) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets the onboarding completed flag in SharedPreferences
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await _instance;
      await prefs.setBool(_keyOnboardingCompleted, completed);
    } catch (_) {}
  }

  /// Clears local storage on logout
  Future<void> clearAll() async {
    try {
      final prefs = await _instance;
      await prefs.remove(_keyUser);
      await prefs.remove(_keyOnboardingCompleted);
    } catch (_) {}
  }
}

