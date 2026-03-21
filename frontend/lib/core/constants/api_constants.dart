/// Centralized API endpoint constants for the SwapTunes backend.
///
/// All route paths are relative to [baseUrl].
class ApiConstants {
  ApiConstants._();

  // ── Base ───────────────────────────────────────────────
  // TODO: load from environment variable / --dart-define for production builds.
  static const String baseUrl = 'http://192.168.8.127:3000/api/v1';

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

  // ── Creator ────────────────────────────────────────────
  static const String creatorSetup = '/creator/setup';
  static const String creatorProfile = '/creator/profile';

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
  static const String discoverFeed = '/discover/feed';
  static const String discoverSearch = '/discover/search';

  // ── Playlists ──────────────────────────────────────────
  static const String playlists = '/playlists';
  static String playlistById(String id) => '/playlists/$id';

  // ── Collabs ────────────────────────────────────────────
  static const String collabs = '/collabs';
  static String collabById(String id) => '/collabs/$id';

  // ── Conversations ──────────────────────────────────────
  static const String conversations = '/conversations';
  static String conversationById(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';

  // ── Notifications ──────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsRead = '/notifications/read';
}
