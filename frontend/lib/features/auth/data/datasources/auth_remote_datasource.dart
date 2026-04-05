import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Handles raw HTTP calls to auth-related backend endpoints.
///
/// This datasource is consumed by [AuthRepository] and should
/// never be accessed directly from the presentation layer.
class AuthRemoteDatasource {
  final ApiClient _client;

  AuthRemoteDatasource(this._client);

  /// POST /auth/profile/setup
  Future<Map<String, dynamic>> setupProfile({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async {
    final result = await _client.post(
      ApiConstants.profileSetup,
      body: {
        'full_name': fullName,
        'username': username,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'genres': genres,
      },
    );
    return result as Map<String, dynamic>;
  }

  /// POST /auth/spotify/connect
  Future<Map<String, dynamic>> connectSpotify({
    required String code,
    required String redirectUri,
  }) async {
    final result = await _client.post(
      ApiConstants.spotifyConnect,
      body: {'code': code, 'redirect_uri': redirectUri},
    );
    return result as Map<String, dynamic>;
  }

  /// GET /auth/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    final result = await _client.get(ApiConstants.me);
    return result as Map<String, dynamic>;
  }
}
