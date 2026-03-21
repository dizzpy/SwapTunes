import 'package:isar/isar.dart';

part 'cached_profile.g.dart';

/// Isar collection for caching user profiles on disk.
///
/// [contentJson] holds the full FullProfileModel serialized as a JSON string.
/// [username] is the lookup key — one entry per username.
/// [cachedAt] is used to evaluate TTL freshness in ProfileRepository.
@Collection()
class CachedProfile {
  Id isarId = Isar.autoIncrement;

  /// Username used as the lookup key.
  @Index(unique: true, replace: true)
  late String username;

  /// Full FullProfileModel serialized as a JSON string.
  late String contentJson;

  /// When this entry was written to cache.
  late DateTime cachedAt;
}
