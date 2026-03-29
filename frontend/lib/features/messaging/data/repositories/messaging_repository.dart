import '../../../../core/services/storage_service.dart';
import '../datasources/messaging_remote_datasource.dart';
import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';

/// Repository for all messaging operations.
///
/// Reads [currentUserId] fresh from [StorageService] at call time so that
/// logout/re-login without a full app restart is handled correctly.
class MessagingRepository {
  final MessagingRemoteDatasource _datasource;
  final StorageService _storage;

  MessagingRepository(this._datasource, this._storage);

  // ── Conversations ──────────────────────────────────────

  Future<List<ChatConversationModel>> getConversations() async {
    final userId = _storage.getUserId() ?? '';
    final data = await _datasource.getConversations();
    return data
        .map((json) => ChatConversationModel.fromApiJson(json, userId))
        .toList();
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

  // ── Messages ───────────────────────────────────────────

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 30,
  }) =>
      _datasource.getMessages(conversationId, before: before, limit: limit);

  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) =>
      _datasource.sendMessage(conversationId, content);

  Future<void> markMessagesRead(String conversationId) =>
      _datasource.markMessagesRead(conversationId);

  Future<void> deleteMessage(String conversationId, String messageId) =>
      _datasource.deleteMessage(conversationId, messageId);

  Future<void> deleteConversation(String conversationId) =>
      _datasource.deleteConversation(conversationId);
}
