import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/messaging_repository.dart';

/// Manages message list state and Supabase Realtime subscription for one chat.
///
/// Lifecycle: create on screen open, dispose on screen close.
/// The Realtime channel is subscribed/unsubscribed automatically.
class SingleChatViewmodel extends ChangeNotifier {
  final MessagingRepository _repository;
  final String conversationId;
  final String currentUserId;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _hasMore = true;
  bool _isReconnecting = false;
  String? _error;

  RealtimeChannel? _channel;

  static const _pageSize = 30;
  int _tempIdCounter = 0;

  // Pending deletes: messageId → timer that fires the actual API call.
  final Map<String, Timer> _pendingDeletes = {};

  SingleChatViewmodel({
    required MessagingRepository repository,
    required this.conversationId,
    required this.currentUserId,
  }) : _repository = repository;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get hasMore => _hasMore;
  bool get isReconnecting => _isReconnecting;
  String? get error => _error;

  // ── Load ───────────────────────────────────────────────

  /// Fetches the latest messages. Call this on screen open, then await it
  /// before calling [markAsRead] to ensure messages are rendered first.
  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _repository.getMessages(
        conversationId,
        limit: _pageSize,
      );
      // Backend returns newest-first; reverse for chronological display.
      _messages = fetched.reversed.toList();
      _hasMore = fetched.length >= _pageSize;
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads messages older than the oldest currently loaded message.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading || _messages.isEmpty) return;

    final oldest = _messages.first.createdAt;
    try {
      final fetched = await _repository.getMessages(
        conversationId,
        before: oldest,
        limit: _pageSize,
      );
      // Prepend in chronological order.
      _messages = [...fetched.reversed, ..._messages];
      _hasMore = fetched.length >= _pageSize;
      notifyListeners();
    } catch (_) {
      // Silent — pagination failure shouldn't disrupt the current view.
    }
  }

  // ── Send ───────────────────────────────────────────────

  /// Optimistically adds [content] to the chat, then confirms via the API.
  ///
  /// A local UUID [tempId] is assigned to the placeholder. When the Realtime
  /// INSERT echo arrives (or the API response), we match by [tempId] and
  /// replace the placeholder with the server-confirmed message.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final tempId = '_temp_${DateTime.now().millisecondsSinceEpoch}_${_tempIdCounter++}';
    final optimistic = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      text: content.trim(),
      isRead: false,
      isDeleted: false,
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, optimistic];
    _isSending = true;
    notifyListeners();

    try {
      final confirmed = await _repository.sendMessage(conversationId, content.trim());
      // Replace the temp placeholder with the server-confirmed message.
      _messages = _messages
          .map((m) => m.id == tempId ? confirmed : m)
          .toList();
    } catch (e) {
      // Remove the optimistic message on failure.
      _messages = _messages.where((m) => m.id != tempId).toList();
      _error = _parseError(e);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ── Delete message ─────────────────────────────────────

  /// Optimistically marks [messageId] as deleted, then schedules the actual
  /// API call after 5 seconds. During that window [undoDeleteMessage] can
  /// cancel the timer and restore the message.
  void deleteMessage(String messageId) {
    _messages = _messages
        .map((m) => m.id == messageId ? m.copyWith(isDeleted: true) : m)
        .toList();
    notifyListeners();

    _pendingDeletes[messageId] = Timer(const Duration(seconds: 5), () async {
      _pendingDeletes.remove(messageId);
      try {
        await _repository.deleteMessage(conversationId, messageId);
      } catch (_) {
        // API failed after undo window — roll back so the user isn't stuck.
        _messages = _messages
            .map((m) => m.id == messageId ? m.copyWith(isDeleted: false) : m)
            .toList();
        notifyListeners();
      }
    });
  }

  /// Cancels a pending delete and restores the message. No-op if the 5-second
  /// window has already passed.
  void undoDeleteMessage(String messageId) {
    final timer = _pendingDeletes.remove(messageId);
    if (timer == null) return;
    timer.cancel();

    _messages = _messages
        .map((m) => m.id == messageId ? m.copyWith(isDeleted: false) : m)
        .toList();
    notifyListeners();
  }

  // ── Read receipts ──────────────────────────────────────

  /// Marks all unread messages as read. Call AFTER [loadMessages] resolves.
  Future<void> markAsRead() async {
    try {
      await _repository.markMessagesRead(conversationId);
    } catch (_) {
      // Silent — read receipts failing should not surface an error.
    }
  }

  // ── Realtime ───────────────────────────────────────────

  /// Subscribes to live message INSERT events for this conversation.
  ///
  /// - Messages from the other user are appended and marked as read.
  /// - Echo messages from self are skipped if the tempId placeholder
  ///   is already in the list (matched by [id] once API response has resolved).
  void subscribeToMessages() {
    final supabase = Supabase.instance.client;

    _channel = supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(
              payload.newRecord,
            );

            // Skip if we already have this message (own send confirmed).
            final alreadyExists =
                _messages.any((m) => m.id == newMessage.id);
            if (alreadyExists) return;

            // Also skip if the placeholder is still present (race condition
            // where Realtime arrives before the API response replaces tempId).
            // We'll rely on the API response path to do the replacement.
            final hasPendingPlaceholder = _messages.any(
              (m) => m.senderId == currentUserId &&
                  m.text == newMessage.text &&
                  newMessage.createdAt.difference(m.createdAt).abs() <
                      const Duration(seconds: 5),
            );
            if (newMessage.senderId == currentUserId && hasPendingPlaceholder) {
              return;
            }

            _messages = [..._messages, newMessage];
            notifyListeners();

            // Auto-mark as read when a new message from the other user arrives.
            if (newMessage.senderId != currentUserId) {
              markAsRead();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final updated = MessageModel.fromJson(payload.newRecord);
            // Only care about is_deleted flipping to true from the other user;
            // own deletes are already applied optimistically.
            if (updated.senderId == currentUserId) return;
            _messages = _messages
                .map((m) => m.id == updated.id ? updated : m)
                .toList();
            notifyListeners();
          },
        )
        .subscribe((status, _) {
          final reconnecting =
              status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.channelError;
          if (_isReconnecting != reconnecting) {
            _isReconnecting = reconnecting;
            notifyListeners();
          }
        });
  }

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void dispose() {
    // Flush pending deletes immediately rather than cancelling them — if the
    // user navigates away within the 5-second undo window the message must
    // still be deleted on the server.
    final pendingIds = List<String>.from(_pendingDeletes.keys);
    for (final id in pendingIds) {
      _pendingDeletes[id]?.cancel();
      _repository.deleteMessage(conversationId, id).catchError((_) {});
    }
    _pendingDeletes.clear();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) return 'Session expired. Please log in again.';
    return e.toString();
  }
}
