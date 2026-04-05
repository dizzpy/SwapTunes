import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wraps the OneSignal Flutter SDK.
///
/// Call [initialize] once before [runApp].
/// Call [login] after the user authenticates (links device to our Supabase UUID).
/// Call [logout] on sign-out.
class OnesignalService {
  static bool _initialized = false;

  /// Initializes the OneSignal SDK and registers the foreground display listener.
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> initialize() async {
    if (_initialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    if (appId.isEmpty) {
      debugPrint('[OnesignalService] ONESIGNAL_APP_ID not set — skipping init');
      return;
    }

    OneSignal.initialize(appId);

    // iOS: show banner even when the app is in the foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Handle notification tap — navigate based on data.type
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data == null) return;
      _handleNotificationTap(data);
    });

    _initialized = true;
  }

  /// Links the current device subscription to the given [userId] (Supabase UUID).
  /// Call this immediately after a successful login.
  static Future<void> login(String userId) async {
    if (!_initialized) return;
    await OneSignal.login(userId);
  }

  /// Unlinks the device from any user account.
  /// Call this on logout.
  static Future<void> logout() async {
    if (!_initialized) return;
    await OneSignal.logout();
  }

  /// Opts the device out of push notifications.
  /// Used by the "Push Notifications" settings toggle (OFF).
  static Future<void> optOut() async {
    if (!_initialized) return;
    await OneSignal.User.pushSubscription.optOut();
  }

  /// Opts the device back into push notifications.
  /// Used by the "Push Notifications" settings toggle (ON).
  static Future<void> optIn() async {
    if (!_initialized) return;
    await OneSignal.User.pushSubscription.optIn();
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // Navigation is handled by the app's navigator key once it's set up.
    // For now, just log the incoming data — deep-link routing can be
    // wired here once named routes are in place.
    debugPrint('[OnesignalService] Notification tapped: $data');
  }
}
