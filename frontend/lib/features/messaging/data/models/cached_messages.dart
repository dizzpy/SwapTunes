import 'package:isar/isar.dart';

part 'cached_messages.g.dart';

/// Isar collection for caching the first page of messages per conversation.
///
/// One row per conversation. [contentJson] holds the page-1 message list
/// (newest-first, matching API response order) as a JSON array.
/// [cachedAt] is used to evaluate TTL freshness in MessagingRepository.
@Collection()
class CachedMessages {
  Id isarId = Isar.autoIncrement;

  /// Conversation id — lookup key, one row per conversation.
  @Index(unique: true, replace: true)
  late String conversationId;

  /// Page-1 List<MessageModel> serialized as a JSON array string (newest-first).
  late String contentJson;

  /// When this entry was written to cache.
  late DateTime cachedAt;
}
