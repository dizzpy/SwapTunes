import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API endpoint constants for the SwapTunes backend.
///
/// All route paths are relative to [baseUrl].
class ApiConstants {
  ApiConstants._();

  // ── Base ───────────────────────────────────────────────
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api/v1';

  // ── Health ─────────────────────────────────────────────
  static const String health = '/health';
  static const String healthDetailed = '/health/detailed';

  // ── Auth ───────────────────────────────────────────────
  static const String profileSetup = '/auth/profile/setup';
  static const String spotifyConnect = '/auth/spotify/connect';
  static const String me = '/auth/me';

  // ── Users ──────────────────────────────────────────────
  static String userProfile(String username) => '/users/$username';
  static String updateMe() => '/users/me';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';
  static String follow(String userId) => '/users/$userId/follow';
  static String unfollow(String userId) => '/users/$userId/unfollow';
  static String userPosts(String userId) => '/users/$userId/posts';
  static String userCollabs(String userId) => '/users/$userId/collabs';

  // ── Creator ────────────────────────────────────────────
  static const String creatorSetup = '/creator/setup';
  static const String creatorProfile = '/creator/profile';
  static const String creatorDeactivate = '/creator/deactivate';

  // ── Uploads ────────────────────────────────────────────
  static const String uploadImage = '/uploads/image';

  // ── Posts ───────────────────────────────────────────────
  static const String postsFeed = '/posts/feed';
  static const String postsCreate = '/posts';
  static String postUpdate(String postId) => '/posts/$postId';
  static String postDelete(String postId) => '/posts/$postId';
  static String postLike(String postId) => '/posts/$postId/like';
  static String postHide(String postId) => '/posts/$postId/hide';
  static String postReport(String postId) => '/posts/$postId/report';
  static String postComments(String postId) => '/posts/$postId/comments';
  static String postCommentUpdate(String postId, String commentId) =>
      '/posts/$postId/comments/$commentId';
  static String postCommentDelete(String postId, String commentId) =>
      '/posts/$postId/comments/$commentId';
  static String postLikers(String postId) => '/posts/$postId/likers';

  // ── Discover ───────────────────────────────────────────
  static const String discoverPlaylists = '/discover/playlists';
  static const String discoverGenres = '/discover/genres';
  static const String discoverUsers = '/discover/users';
  static const String discoverSearch = '/discover/search';
  static const String discoverTrending = '/discover/trending';

  // ── Playlists ──────────────────────────────────────────
  static const String playlists = '/playlists';
  static const String playlistCreate = '/playlists/create';
  static const String spotifyAvailable = '/playlists/spotify/available';
  static const String playlistImport = '/playlists/import';
  static String playlistById(String id) => '/playlists/$id';
  static String playlistLike(String id) => '/playlists/$id/like';
  static String userPlaylists(String userId) => '/playlists/user/$userId';

  // ── Collabs ────────────────────────────────────────────
  static const String collabs = '/collabs';
  static const String myCollabs = '/collabs/me';
  static String collabById(String id) => '/collabs/$id';

  // ── Conversations ──────────────────────────────────────
  static const String conversations = '/conversations';
  static String conversationById(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';
  static String conversationMarkRead(String id) => '/conversations/$id/read';
  static String conversationMessageById(
    String conversationId,
    String messageId,
  ) => '/conversations/$conversationId/messages/$messageId';

  // ── Dev (non-production only) ──────────────────────────
  static const String devResetRole = '/dev/reset-role';

  // ── Notifications ──────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsMarkAllRead = '/notifications/read-all';
}
