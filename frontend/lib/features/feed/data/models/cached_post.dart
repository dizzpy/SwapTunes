import 'package:isar/isar.dart';

part 'cached_post.g.dart';

/// Isar collection for caching feed posts on disk.
///
/// [contentJson] holds the full PostModel serialized as a JSON string.
/// [page] tracks which page this post belongs to (for pagination cache).
/// [cachedAt] is used to evaluate TTL freshness in FeedRepository.
@Collection()
class CachedPost {
  Id isarId = Isar.autoIncrement;

  /// The server-side post id (e.g. UUID).
  @Index()
  late String postId;

  /// Which feed page this post belongs to.
  @Index()
  late int page;

  /// Full PostModel serialized as a JSON string.
  late String contentJson;

  /// When this entry was written to cache.
  late DateTime cachedAt;
}
