import 'dart:convert';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:isar/isar.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/cached_profile.dart';
import '../models/cached_user_post.dart';
import '../models/full_profile_model.dart';
import '../models/follow_user_model.dart';
import '../../../collab/data/models/collab_model.dart';
import '../../../feed/data/models/post_model.dart';

/// Repository for all profile-related operations.
///
/// Replaces the previous in-memory cache with a persistent Isar disk cache
/// (5-min TTL) so profile data survives app restarts.
/// User posts (profile tab) are also cached per userId.
class ProfileRepository {
  final ApiClient _client;
  final ProfileRemoteDatasource _datasource;
  final Isar _isar;

  static const _cacheTtl = Duration(minutes: 5);

  ProfileRepository(this._client, this._datasource, this._isar);

  // ── Profile ────────────────────────────────────────────

  /// Returns a cached profile if fresh, otherwise fetches from network.
  ///
  /// [forceRefresh] bypasses the cache — use this for pull-to-refresh.
  Future<FullProfileModel> getUserProfile(
    String username, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _getCachedProfile(username);
      if (cached != null) return cached;
    }

    final profile = await _datasource.getUserProfile(username);
    await _cacheProfile(username, profile);
    return profile;
  }

  /// Invalidates a specific profile from the Isar cache (call after editing).
  Future<void> invalidateCache(String username) async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles.filter().usernameEqualTo(username).deleteAll();
    });
  }

  // ── Profile cache helpers ──────────────────────────────

  Future<FullProfileModel?> _getCachedProfile(String username) async {
    final cutoff = DateTime.now().subtract(_cacheTtl);
    final row = await _isar.cachedProfiles
        .filter()
        .usernameEqualTo(username)
        .cachedAtGreaterThan(cutoff)
        .findFirst();
    if (row == null) return null;
    return _deserializeProfile(row);
  }

  Future<void> _cacheProfile(String username, FullProfileModel profile) async {
    final row = CachedProfile()
      ..username = username
      ..contentJson = jsonEncode(_serializeProfile(profile))
      ..cachedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles.put(row);
    });
  }

  FullProfileModel _deserializeProfile(CachedProfile row) {
    return FullProfileModel.fromJson(
      jsonDecode(row.contentJson) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _serializeProfile(FullProfileModel p) => {
    'id': p.id,
    'full_name': p.fullName,
    'username': p.username,
    'bio': p.bio,
    'avatar_url': p.avatarUrl,
    'cover_url': p.coverUrl,
    'user_type': p.userType,
    'is_verified': p.isVerified,
    'spotify_connected': p.spotifyConnected,
    'created_at': p.createdAt.toIso8601String(),
    'username_changed_at': p.usernameChangedAt?.toIso8601String(),
    'genres': p.genres,
    'stats': {
      'followers': p.stats.followers,
      'following': p.stats.following,
      'posts': p.stats.posts,
      'playlists': p.stats.playlists,
      'collabs': p.stats.collabs,
    },
    'is_following': p.isFollowing,
    'creator_profiles': p.creatorProfile == null
        ? []
        : [
            {
              'role_title': p.creatorProfile!.roleTitle,
              'location': p.creatorProfile!.location,
              'specializations': p.creatorProfile!.specializations,
              'soundcloud_url': p.creatorProfile!.soundcloudUrl,
              'youtube_url': p.creatorProfile!.youtubeUrl,
              'spotify_artist_url': p.creatorProfile!.spotifyArtistUrl,
              'apple_music_url': p.creatorProfile!.appleMusicUrl,
              'portfolio_url': p.creatorProfile!.portfolioUrl,
            },
          ],
  };

  // ── Update profile ─────────────────────────────────────

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

  // ── Follow / Unfollow ──────────────────────────────────

  Future<void> followUser(String userId) => _datasource.followUser(userId);

  Future<void> unfollowUser(String userId) => _datasource.unfollowUser(userId);

  // ── Followers / Following ─────────────────────────────

  Future<List<FollowUserModel>> getFollowers(String userId, {int page = 1}) =>
      _datasource.getFollowers(userId, page: page);

  Future<List<FollowUserModel>> getFollowing(String userId, {int page = 1}) =>
      _datasource.getFollowing(userId, page: page);

  // ── User posts (profile tab) ───────────────────────────

  /// Returns cached user posts if fresh, otherwise fetches from network.
  ///
  /// [forceRefresh] bypasses the cache — use this for pull-to-refresh.
  Future<List<PostModel>> getUserPosts(
    String userId, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (page == 1 && !forceRefresh) {
      final cached = await _getCachedUserPosts(userId);
      if (cached != null) return cached;
    }

    final posts = await _datasource.getUserPosts(userId, page: page);
    if (page == 1) await _cacheUserPosts(userId, posts);
    return posts;
  }

  // ── User posts cache helpers ───────────────────────────

  Future<List<PostModel>?> _getCachedUserPosts(String userId) async {
    final cutoff = DateTime.now().subtract(_cacheTtl);
    final row = await _isar.cachedUserPosts
        .filter()
        .userIdEqualTo(userId)
        .cachedAtGreaterThan(cutoff)
        .findFirst();
    if (row == null) return null;
    final list = jsonDecode(row.contentJson) as List;
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _cacheUserPosts(String userId, List<PostModel> posts) async {
    final serialized = posts.map(_serializePost).toList();
    final row = CachedUserPost()
      ..userId = userId
      ..contentJson = jsonEncode(serialized)
      ..cachedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.cachedUserPosts.put(row);
    });
  }

  Map<String, dynamic> _serializePost(PostModel p) => {
    'id': p.id,
    'user_id': p.userId,
    'content': p.content,
    'image_url': p.imageUrl,
    'likes_count': p.likesCount,
    'comments_count': p.commentsCount,
    'is_liked': p.isLiked,
    'created_at': p.createdAt.toIso8601String(),
    'user': {
      'username': p.authorUsername,
      'full_name': p.authorFullName,
      'avatar_url': p.authorAvatarUrl,
      'is_verified': p.authorIsVerified,
    },
  };

  // ── Image upload ───────────────────────────────────────

  Future<String> uploadImage(XFile image) => _datasource.uploadImage(image);

  // ── User collabs (profile tab) ─────────────────────────

  /// Fetches collabs for a user's profile page (no caching for now).
  Future<List<CollabModel>> getUserCollabs(String userId, {int page = 1}) =>
      _datasource.getUserCollabs(userId, page: page);
}
