import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/message_model.dart';

/// Remote datasource for all messaging API calls.
///
/// Returns raw JSON for conversation lists (repository applies the
/// currentUserId transform) and typed [MessageModel] objects for messages.
/// All HTTP calls go through the Express backend.
class MessagingRemoteDatasource {
  final ApiClient _client;

  MessagingRemoteDatasource(this._client);

  // ── Conversations ──────────────────────────────────────

  /// Returns raw JSON list. Repository converts to [ChatConversationModel].
  Future<List<Map<String, dynamic>>> getConversations() async {
    final data = await _client.get(ApiConstants.conversations) as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Creates or returns an existing conversation with [recipientId].
  /// Returns raw JSON. Repository converts to [ChatConversationModel].
  Future<Map<String, dynamic>> startConversation(
    String recipientId, {
    String? collabId,
  }) async {
    final body = <String, dynamic>{'recipient_id': recipientId};
    if (collabId != null) body['collab_id'] = collabId;
    final data = await _client.post(ApiConstants.conversations, body: body);
    return data as Map<String, dynamic>;
  }

  // ── Messages ───────────────────────────────────────────

  /// Returns messages for [conversationId], newest first.
  ///
  /// Pass [before] to load messages older than that timestamp (load-more).
  /// The caller is responsible for reversing the list for chronological display.
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 30,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (before != null) params['before'] = before.toUtc().toIso8601String();

    final data = await _client.get(
      ApiConstants.conversationMessages(conversationId),
      queryParams: params,
    ) as List;

    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message to [conversationId]. Returns the created [MessageModel].
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final data = await _client.post(
      ApiConstants.conversationMessages(conversationId),
      body: {'content': content},
    );
    return MessageModel.fromJson(data as Map<String, dynamic>);
  }

  /// Marks all unread messages from the other user as read.
  Future<void> markMessagesRead(String conversationId) async {
    await _client.patch(ApiConstants.conversationMarkRead(conversationId));
  }

  /// Soft-deletes a single message (sender only). The other participant sees
  /// a "This message was deleted" placeholder.
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _client.delete(
      ApiConstants.conversationMessageById(conversationId, messageId),
    );
  }

  /// Deletes a conversation and all its messages.
  Future<void> deleteConversation(String conversationId) async {
    await _client.delete(ApiConstants.conversationById(conversationId));
  }
}
