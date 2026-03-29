import 'package:isar/isar.dart';

part 'cached_conversation.g.dart';

/// Isar collection for caching the conversations inbox on disk.
///
/// One row per logged-in user. [contentJson] holds the full
/// List<ChatConversationModel> serialized as a JSON array.
/// [cachedAt] is used to evaluate TTL freshness in MessagingRepository.
@Collection()
class CachedConversation {
  Id isarId = Isar.autoIncrement;

  /// Current user's id — lookup key, one row per user.
  @Index(unique: true, replace: true)
  late String userId;

  /// Full List<ChatConversationModel> serialized as a JSON array string.
  late String contentJson;

  /// When this entry was written to cache.
  late DateTime cachedAt;
}
