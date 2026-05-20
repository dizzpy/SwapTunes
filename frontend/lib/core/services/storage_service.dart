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

  // ── Notification Preferences ──────────────────────────

  static const _keyPushEnabled = 'notif_push_enabled';
  static const _keyActivityEnabled = 'notif_activity_enabled';
  static const _keyMessageEnabled = 'notif_message_enabled';
  static const _keyCollabEnabled = 'notif_collab_enabled';

  bool get pushNotificationsEnabled => _prefs.getBool(_keyPushEnabled) ?? true;
  bool get activityNotificationsEnabled => _prefs.getBool(_keyActivityEnabled) ?? true;
  bool get messageNotificationsEnabled => _prefs.getBool(_keyMessageEnabled) ?? true;
  bool get collabNotificationsEnabled => _prefs.getBool(_keyCollabEnabled) ?? true;

  Future<void> setPushNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyPushEnabled, value);
  Future<void> setActivityNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyActivityEnabled, value);
  Future<void> setMessageNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyMessageEnabled, value);
  Future<void> setCollabNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyCollabEnabled, value);

  // ── Dev Settings ──────────────────────────────────────

  static const _keyDevBaseUrl = 'dev_base_url';
  static const _keyDevGeminiKey = 'dev_gemini_key';

  String? getDevBaseUrl() => _prefs.getString(_keyDevBaseUrl);

  Future<void> setDevBaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_keyDevBaseUrl);
    } else {
      await _prefs.setString(_keyDevBaseUrl, url.trim());
    }
  }

  String? getDevGeminiKey() => _prefs.getString(_keyDevGeminiKey);

  Future<void> setDevGeminiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _prefs.remove(_keyDevGeminiKey);
    } else {
      await _prefs.setString(_keyDevGeminiKey, key.trim());
    }
  }

  // ── Clear All ──────────────────────────────────────────

  /// Wipes all stored data (used on logout). Dev Settings (manual base URL +
  /// Gemini key) are preserved so emergency overrides survive a logout.
  Future<void> clearAll() async {
    final devBaseUrl = _prefs.getString(_keyDevBaseUrl);
    final devGeminiKey = _prefs.getString(_keyDevGeminiKey);
    await _prefs.clear();
    if (devBaseUrl != null) await _prefs.setString(_keyDevBaseUrl, devBaseUrl);
    if (devGeminiKey != null) await _prefs.setString(_keyDevGeminiKey, devGeminiKey);
  }
}
