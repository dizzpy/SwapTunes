import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../../core/services/storage_service.dart';
import '../datasources/messaging_remote_datasource.dart';
import '../models/cached_conversation.dart';
import '../models/cached_messages.dart';
import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';

/// Repository for all messaging operations.
///
/// Adds a persistent Isar disk cache:
/// - Conversations inbox cached per userId with a 2-minute TTL.
/// - Page-1 messages cached per conversationId with a 1-minute TTL.
///
/// All mutation operations (send, delete, markRead) are never cached and
/// always delegate directly to [MessagingRemoteDatasource].
class MessagingRepository {
  final MessagingRemoteDatasource _datasource;
  final StorageService _storage;
  final Isar _isar;

  static const _convoCacheTtl = Duration(minutes: 2);
  static const _msgCacheTtl = Duration(minutes: 1);

  MessagingRepository(this._datasource, this._storage, this._isar);

  // ── Conversations ──────────────────────────────────────

  /// Returns the conversations list for the current user.
  ///
  /// Served from Isar cache when fresh (< 2 min).
  /// [forceRefresh] bypasses the cache — used by Realtime callbacks so a
  /// live inbox UPDATE always fetches fresh data regardless of TTL.
  /// On API failure, stale cache is returned silently as a fallback.
  Future<List<ChatConversationModel>> getConversations({
    bool forceRefresh = false,
  }) async {
    final userId = _storage.getUserId() ?? '';

    if (!forceRefresh) {
      final cached = await _getCachedConversations(userId);
      if (cached != null) return cached;
    }

    try {
      final data = await _datasource.getConversations();
      final conversations = data
          .map((json) => ChatConversationModel.fromApiJson(json, userId))
          .toList();
      await _cacheConversations(userId, conversations);
      return conversations;
    } catch (_) {
      final stale = await _getStaleCachedConversations(userId);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<ChatConversationModel> startConversation(
    String recipientId, {
    String? collabId,
  }) async {
    final userId = _storage.getUserId() ?? '';
    final json = await _datasource.startConversation(
      recipientId,
      collabId: collabId,
    );
    return ChatConversationModel.fromApiJson(json, userId);
  }

  /// Soft-deletes the conversation for the current user and invalidates
  /// the full conversations cache so the next load fetches fresh.
  Future<void> deleteConversation(String conversationId) async {
    await _datasource.deleteConversation(conversationId);
    final userId = _storage.getUserId() ?? '';
    await _invalidateConversationsCache(userId);
  }

  // ── Messages ───────────────────────────────────────────

  /// Returns messages for [conversationId].
  ///
  /// Page-1 (when [before] is null) is served from Isar cache when fresh
  /// (< 1 min). [forceRefresh] bypasses cache for explicit refresh scenarios.
  /// On API failure with a stale page-1 cache, stale data is returned silently.
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    final isPageOne = before == null;

    if (isPageOne && !forceRefresh) {
      final cached = await _getCachedMessages(conversationId);
      if (cached != null) return cached;
    }

    try {
      final messages = await _datasource.getMessages(
        conversationId,
        before: before,
        limit: limit,
      );
      if (isPageOne) await _cacheMessages(conversationId, messages);
      return messages;
    } catch (_) {
      if (isPageOne) {
        final stale = await _getStaleCachedMessages(conversationId);
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  /// Sends a message and invalidates the message cache for [conversationId]
  /// so the next load reflects the new message.
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final message = await _datasource.sendMessage(conversationId, content);
    await _invalidateMessagesCache(conversationId);
    return message;
  }

  Future<void> markMessagesRead(String conversationId) =>
      _datasource.markMessagesRead(conversationId);

  Future<void> deleteMessage(String conversationId, String messageId) =>
      _datasource.deleteMessage(conversationId, messageId);

  // ── Conversations cache helpers ────────────────────────

  Future<List<ChatConversationModel>?> _getCachedConversations(
    String userId,
  ) async {
    final cutoff = DateTime.now().subtract(_convoCacheTtl);
    final row = await _isar.cachedConversations
        .filter()
        .userIdEqualTo(userId)
        .cachedAtGreaterThan(cutoff)
        .findFirst();
    if (row == null) return null;
    return _deserializeConversations(row.contentJson);
  }

  Future<List<ChatConversationModel>?> _getStaleCachedConversations(
    String userId,
  ) async {
    final row = await _isar.cachedConversations
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
    if (row == null) return null;
    return _deserializeConversations(row.contentJson);
  }

  Future<void> _cacheConversations(
    String userId,
    List<ChatConversationModel> conversations,
  ) async {
    final row = CachedConversation()
      ..userId = userId
      ..contentJson = jsonEncode(conversations.map(_serializeConversation).toList())
      ..cachedAt = DateTime.now();

    await _isar.writeTxn(() => _isar.cachedConversations.put(row));
  }

  Future<void> _invalidateConversationsCache(String userId) async {
    await _isar.writeTxn(
      () => _isar.cachedConversations.filter().userIdEqualTo(userId).deleteAll(),
    );
  }

  // ── Messages cache helpers ─────────────────────────────

  Future<List<MessageModel>?> _getCachedMessages(String conversationId) async {
    final cutoff = DateTime.now().subtract(_msgCacheTtl);
    final row = await _isar.cachedMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .cachedAtGreaterThan(cutoff)
        .findFirst();
    if (row == null) return null;
    return _deserializeMessages(row.contentJson);
  }

  Future<List<MessageModel>?> _getStaleCachedMessages(
    String conversationId,
  ) async {
    final row = await _isar.cachedMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .findFirst();
    if (row == null) return null;
    return _deserializeMessages(row.contentJson);
  }

  Future<void> _cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {
    final row = CachedMessages()
      ..conversationId = conversationId
      ..contentJson = jsonEncode(messages.map((m) => m.toJson()).toList())
      ..cachedAt = DateTime.now();

    await _isar.writeTxn(() => _isar.cachedMessages.put(row));
  }

  Future<void> _invalidateMessagesCache(String conversationId) async {
    await _isar.writeTxn(
      () => _isar.cachedMessages
          .filter()
          .conversationIdEqualTo(conversationId)
          .deleteAll(),
    );
  }

  // ── Serialization helpers ──────────────────────────────

  Map<String, dynamic> _serializeConversation(ChatConversationModel c) => {
    'id': c.id,
    'participant_id': c.participantId,
    'participant_name': c.participantName,
    'participant_avatar_url': c.participantAvatarUrl,
    'is_online': c.isOnline,
    'last_message': c.lastMessage,
    'last_message_at': c.lastMessageAt.toIso8601String(),
    'unread_count': c.unreadCount,
  };

  List<ChatConversationModel> _deserializeConversations(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return ChatConversationModel(
        id: m['id'] as String,
        participantId: m['participant_id'] as String,
        participantName: m['participant_name'] as String? ?? '',
        participantAvatarUrl: m['participant_avatar_url'] as String?,
        isOnline: (m['is_online'] as bool?) ?? false,
        lastMessage: m['last_message'] as String? ?? '',
        lastMessageAt: DateTime.parse(m['last_message_at'] as String),
        unreadCount: (m['unread_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  List<MessageModel> _deserializeMessages(String json) {
    final list = jsonDecode(json) as List;
    return list
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
