import 'package:shared_preferences/shared_preferences.dart';

/// Handles local persistence for auth tokens and user preferences.
///
/// Uses SharedPreferences for lightweight key-value storage.
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  late final SharedPreferences _prefs;

  /// Must be called once before using any storage methods.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Token Management ───────────────────────────────────

  /// Persists the JWT auth token received from the backend.
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Retrieves the stored JWT token, or null if not logged in.
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Clears the stored JWT token on logout.
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// Whether a valid token exists.
  bool get hasToken => getToken() != null;

  // ── User ID ────────────────────────────────────────────

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  // ── Onboarding ─────────────────────────────────────────

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingCompleteKey, value);
  }

  bool get isOnboardingComplete {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // ── Recent Searches ────────────────────────────────────

  static const String _recentSearchesKey = 'recent_searches';

  Future<void> saveRecentSearches(List<String> queries) async {
    await _prefs.setStringList(_recentSearchesKey, queries);
  }

  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  // ── Clear All ──────────────────────────────────────────

  /// Wipes all stored data (used on logout).
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
