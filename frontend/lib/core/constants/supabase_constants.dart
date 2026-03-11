import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project configuration for SwapTunes.
///
/// Values are loaded from the local `.env` file so secrets do not live in code.
class SupabaseConstants {
  SupabaseConstants._();

  /// Your Supabase project URL (e.g. https://xxxx.supabase.co).
  static String get url => _readRequired('SUPABASE_URL');

  /// Your Supabase anon/public key.
  static String get anonKey => _readRequired('SUPABASE_ANON_KEY');

  /// Deep-link callback scheme used by OAuth providers.
  static String get redirectScheme =>
      dotenv.env['SUPABASE_REDIRECT_SCHEME'] ?? 'io.supabase.swaptune';

  /// Full redirect URL for OAuth callbacks.
  static String get redirectUrl =>
      dotenv.env['SUPABASE_REDIRECT_URL'] ?? '$redirectScheme://login-callback';

  static String _readRequired(String key) {
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      throw StateError(
        'Missing required env variable: $key. Fill it in .env before running the app.',
      );
    }
    return value;
  }
}
