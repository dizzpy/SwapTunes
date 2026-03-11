import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Repository for profile-related API operations.
///
/// Handles profile updates via `PATCH /users/me`.
class ProfileRepository {
  final ApiClient _client;

  ProfileRepository(this._client);

  /// Updates the current user's profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    List<String>? genres,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (genres != null) body['genres'] = genres;

    await _client.patch(ApiConstants.updateMe(), body: body);
  }
}
