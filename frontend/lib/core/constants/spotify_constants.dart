import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Spotify configuration for the connect (playlist import) flow.
class SpotifyConstants {
  SpotifyConstants._();

  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  static String get connectRedirectUri =>
      dotenv.env['SPOTIFY_CONNECT_REDIRECT_URI'] ?? '';

  /// Scopes requested during the connect flow (read-only playlist access).
  static const List<String> connectScopes = [
    'playlist-read-private',
    'playlist-read-collaborative',
  ];

  /// Builds the Spotify authorization URL for the connect flow.
  static Uri buildAuthorizationUrl() {
    return Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': connectRedirectUri,
      'scope': connectScopes.join(' '),
      'show_dialog': 'true',
    });
  }
}
