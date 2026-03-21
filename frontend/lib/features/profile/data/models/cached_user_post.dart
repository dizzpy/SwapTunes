import 'package:isar/isar.dart';

part 'cached_user_post.g.dart';

/// Isar collection for caching a user's own posts (profile tab) on disk.
///
/// [contentJson] holds a JSON-encoded list of PostModel objects.
/// [userId] is the lookup key — one entry per user.
/// [cachedAt] is used to evaluate TTL freshness in ProfileRepository.
@Collection()
class CachedUserPost {
  Id isarId = Isar.autoIncrement;

  /// User id used as the lookup key.
  @Index(unique: true, replace: true)
  late String userId;

  /// JSON-encoded list of PostModel objects: `jsonEncode(posts.map(...).toList())`.
  late String contentJson;

  /// When this entry was written to cache.
  late DateTime cachedAt;
}
