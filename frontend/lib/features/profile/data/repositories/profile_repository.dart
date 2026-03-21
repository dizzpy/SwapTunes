import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/full_profile_model.dart';
import '../models/follow_user_model.dart';
import '../../../feed/data/models/post_model.dart';

/// Repository for all profile-related operations.
///
/// Keeps [ApiClient] for the existing `updateProfile` PATCH call.
/// All fetch / follow operations delegate to [ProfileRemoteDatasource].
/// In-memory cache (5-min TTL) prevents redundant network calls when
/// navigating back to recently visited profiles.
class ProfileRepository {
  final ApiClient _client;
  final ProfileRemoteDatasource _datasource;

  ProfileRepository(this._client, this._datasource);

  // ── In-memory profile cache ──────────────────────────────────────
  final _cache = <String, (FullProfileModel, DateTime)>{};
  static const _cacheTtl = Duration(minutes: 5);

  /// Returns a cached profile if fresh, otherwise fetches from network.
  Future<FullProfileModel> getUserProfile(String username,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache[username];
      if (cached != null &&
          DateTime.now().difference(cached.$2) < _cacheTtl) {
        return cached.$1;
      }
    }
    final profile = await _datasource.getUserProfile(username);
    _cache[username] = (profile, DateTime.now());
    return profile;
  }

  /// Invalidate a specific profile from the cache (call after editing).
  void invalidateCache(String username) => _cache.remove(username);

  // ── PATCH /users/me — update own profile fields ─────────────────
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? username,
    List<String>? genres,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (coverUrl != null) body['cover_url'] = coverUrl;
    if (username != null) body['username'] = username;
    if (genres != null) body['genres'] = genres;

    await _client.patch(ApiConstants.updateMe(), body: body);
  }

  /// POST /users/:userId/follow
  Future<void> followUser(String userId) => _datasource.followUser(userId);

  /// DELETE /users/:userId/unfollow
  Future<void> unfollowUser(String userId) => _datasource.unfollowUser(userId);

  /// GET /users/:userId/followers (paginated)
  Future<List<FollowUserModel>> getFollowers(String userId, {int page = 1}) =>
      _datasource.getFollowers(userId, page: page);

  /// GET /users/:userId/following (paginated)
  Future<List<FollowUserModel>> getFollowing(String userId, {int page = 1}) =>
      _datasource.getFollowing(userId, page: page);

  /// GET /users/:userId/posts (paginated)
  Future<List<PostModel>> getUserPosts(String userId, {int page = 1}) =>
      _datasource.getUserPosts(userId, page: page);

  /// Upload an image and return its CDN URL.
  Future<String> uploadImage(XFile image) => _datasource.uploadImage(image);
}
