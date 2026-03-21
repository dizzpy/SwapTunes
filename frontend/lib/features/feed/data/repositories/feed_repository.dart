import 'dart:convert';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:isar/isar.dart';

import '../datasources/feed_remote_datasource.dart';
import '../models/cached_post.dart';
import '../models/comment_model.dart';
import '../models/liker_model.dart';
import '../models/post_model.dart';

/// Repository for all feed-related operations.
///
/// Adds a persistent Isar disk cache for page-1 feed posts.
/// All other operations (comments, likes, etc.) delegate directly
/// to [FeedRemoteDatasource] — they are not cached.
class FeedRepository {
  final FeedRemoteDatasource _datasource;
  final Isar _isar;

  static const _cacheTtl = Duration(minutes: 5);

  FeedRepository(this._datasource, this._isar);

  // ── Feed ───────────────────────────────────────────────

  /// Returns feed posts for [page].
  ///
  /// Page 1 is served from Isar cache when fresh (< 5 min).
  /// [forceRefresh] bypasses the cache — use this for pull-to-refresh.
  /// On API failure with a stale page-1 cache, stale data is returned silently.
  Future<List<PostModel>> getFeed({
    int page = 1,
    int limit = kFeedPageSize,
    bool forceRefresh = false,
  }) async {
    // Only cache page 1 — subsequent pages are always fetched fresh.
    if (page == 1 && !forceRefresh) {
      final cached = await _getCachedPage1();
      if (cached != null) return cached;
    }

    try {
      final posts = await _datasource.getFeed(page: page, limit: limit);
      if (page == 1) await _cachePage1(posts);
      return posts;
    } catch (e) {
      // On failure, return stale page-1 cache silently rather than surfacing an error.
      if (page == 1) {
        final stale = await _getStalePage1();
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  // ── Cache helpers ──────────────────────────────────────

  /// Returns cached page-1 posts if they are within TTL, otherwise null.
  Future<List<PostModel>?> _getCachedPage1() async {
    final cutoff = DateTime.now().subtract(_cacheTtl);
    final rows = await _isar.cachedPosts
        .filter()
        .pageEqualTo(1)
        .cachedAtGreaterThan(cutoff)
        .findAll();
    if (rows.isEmpty) return null;
    return rows.map(_deserialize).toList();
  }

  /// Returns stale page-1 posts regardless of TTL (used as silent fallback).
  Future<List<PostModel>?> _getStalePage1() async {
    final rows = await _isar.cachedPosts
        .filter()
        .pageEqualTo(1)
        .findAll();
    if (rows.isEmpty) return null;
    return rows.map(_deserialize).toList();
  }

  /// Replaces the page-1 cache with [posts].
  Future<void> _cachePage1(List<PostModel> posts) async {
    final now = DateTime.now();
    final rows = posts.map((p) {
      return CachedPost()
        ..postId = p.id
        ..page = 1
        ..contentJson = jsonEncode(_serialize(p))
        ..cachedAt = now;
    }).toList();

    await _isar.writeTxn(() async {
      // Clear old page-1 entries before writing fresh ones.
      await _isar.cachedPosts.filter().pageEqualTo(1).deleteAll();
      await _isar.cachedPosts.putAll(rows);
    });
  }

  PostModel _deserialize(CachedPost row) {
    return PostModel.fromJson(
      jsonDecode(row.contentJson) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _serialize(PostModel p) => {
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

  // ── Create ─────────────────────────────────────────────

  Future<PostModel> createPost(String content, {String? imageUrl}) =>
      _datasource.createPost(content, imageUrl: imageUrl);

  Future<String> uploadImage(XFile image) => _datasource.uploadImage(image);

  // ── Like / Unlike ──────────────────────────────────────

  Future<void> likePost(String postId) => _datasource.likePost(postId);

  Future<void> unlikePost(String postId) => _datasource.unlikePost(postId);

  // ── Edit / Delete ──────────────────────────────────────

  Future<PostModel> updatePost(
    String postId, {
    String? content,
    String? imageUrl,
  }) => _datasource.updatePost(postId, content: content, imageUrl: imageUrl);

  Future<void> deletePost(String postId) => _datasource.deletePost(postId);

  Future<void> hidePost(String postId) => _datasource.hidePost(postId);

  Future<void> reportPost(String postId, String reason) =>
      _datasource.reportPost(postId, reason);

  // ── Comments ───────────────────────────────────────────

  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 30,
  }) => _datasource.getComments(postId, page: page, limit: limit);

  Future<CommentModel> addComment(String postId, String content) =>
      _datasource.addComment(postId, content);

  Future<CommentModel> updateComment(
    String postId,
    String commentId,
    String content,
  ) => _datasource.updateComment(postId, commentId, content);

  Future<void> deleteComment(String postId, String commentId) =>
      _datasource.deleteComment(postId, commentId);

  // ── Likers ─────────────────────────────────────────────

  Future<List<LikerModel>> getLikers(String postId) =>
      _datasource.getLikers(postId);
}
