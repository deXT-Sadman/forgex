import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Wraps SharedPreferences so the rest of the app doesn't touch it directly.
/// This is what powers "Offline Support": whatever was last fetched from
/// MongoDB gets mirrored here, and the app reads from here whenever a
/// network call fails.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------- Auth token ----------
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(PrefsKeys.authToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(PrefsKeys.authToken);
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove(PrefsKeys.authToken);
  }

  // ---------- Current user ----------
  Future<void> saveUser(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(PrefsKeys.currentUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(PrefsKeys.currentUser);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<void> clearUser() async {
    final prefs = await _prefs;
    await prefs.remove(PrefsKeys.currentUser);
  }

  // ---------- Tasks cache (used from Day 4 onward) ----------
  Future<void> saveTasks(List<TaskModel> tasks) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(tasks.map((t) => t.toCacheJson()).toList());
    await prefs.setString(PrefsKeys.cachedTasks, encoded);
  }

  Future<List<TaskModel>> getCachedTasks() async {
    final prefs = await _prefs;
    final raw = prefs.getString(PrefsKeys.cachedTasks);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded
        .map((e) => TaskModel.fromCacheJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> clearTasks() async {
    final prefs = await _prefs;
    await prefs.remove(PrefsKeys.cachedTasks);
  }

  // ---------- Theme (used from Day 3 onward) ----------
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(PrefsKeys.themeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(PrefsKeys.themeMode);
  }

  /// Wipe everything on logout.
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(PrefsKeys.authToken);
    await prefs.remove(PrefsKeys.currentUser);
    await prefs.remove(PrefsKeys.cachedTasks);
    await prefs.remove(PrefsKeys.pendingTaskOps);
  }
}
