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
  bool _isPaginating = false;
  String? _error;

  RealtimeChannel? _channel;
  Timer? _readDebounce;

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
  bool get isPaginating => _isPaginating;
  String? get error => _error;

  // ── Load ───────────────────────────────────────────────

  /// Loads messages with a stale-while-revalidate strategy:
  ///
  /// 1. Renders any cached messages instantly (no spinner shown because
  ///    [_buildMessageList] only shows a spinner when messages are empty).
  /// 2. Fetches fresh messages from the API in the background.
  /// 3. Updates the UI silently if the fresh data differs.
  ///
  /// On first open with no cache, falls back to the normal loading spinner.
  Future<void> loadMessages() async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    // Phase 1 — show stale cache immediately so the screen feels instant.
    final cached = await _repository.getCachedMessagesStale(conversationId);
    if (cached != null && cached.isNotEmpty) {
      _messages = cached.reversed.toList();
      _hasMore = cached.length >= _pageSize;
      notifyListeners(); // messages not empty → spinner hidden even with _isLoading
    }

    // Phase 2 — background refresh to pick up any new messages.
    try {
      final fetched = await _repository.getMessages(
        conversationId,
        limit: _pageSize,
        forceRefresh: true,
      );
      _messages = fetched.reversed.toList();
      _hasMore = fetched.length >= _pageSize;
    } catch (e) {
      // If we already have cached messages on screen, swallow the error.
      if (_messages.isEmpty) _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads messages older than the oldest currently loaded message.
  Future<void> loadMore() async {
    if (!_hasMore || _isPaginating || _isLoading || _messages.isEmpty) return;

    _isPaginating = true;
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
    } catch (_) {
      // Silent — pagination failure shouldn't disrupt the current view.
    } finally {
      _isPaginating = false;
      notifyListeners();
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
      status: MessageStatus.sending,
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
      // Mark as failed — keep it visible so the user can retry.
      _messages = _messages
          .map((m) => m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m)
          .toList();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Retries sending a failed message.
  ///
  /// Removes the failed placeholder first so there is never two bubbles for
  /// the same content, then delegates to [sendMessage] which adds a fresh
  /// optimistic entry and handles the full send + failure cycle.
  Future<void> retryMessage(String tempId) async {
    final idx = _messages.indexWhere((m) => m.id == tempId);
    if (idx == -1) return;
    final text = _messages[idx].text;
    _messages.removeAt(idx);
    notifyListeners();
    await sendMessage(text);
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

  /// Debounced version used by the Realtime callback — coalesces rapid
  /// incoming messages into a single API call 600 ms after the last one.
  void _scheduleMarkAsRead() {
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 600), markAsRead);
  }

  /// Fetches the latest page of messages and merges any that arrived while
  /// the WebSocket was disconnected (gap-fill after reconnect).
  Future<void> _fillGap() async {
    try {
      final fresh = await _repository.getMessages(
        conversationId,
        limit: _pageSize,
        forceRefresh: true,
      );
      if (fresh.isEmpty) return;
      final existingIds = _messages.map((m) => m.id).toSet();
      final newOnly = fresh.reversed
          .where((m) => !existingIds.contains(m.id))
          .toList();
      if (newOnly.isNotEmpty) {
        _messages = [..._messages, ...newOnly];
        notifyListeners();
      }
    } catch (_) {
      // Silent — gap-fill failure should not surface an error.
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

            // Debounced mark-as-read for messages from the other user.
            if (newMessage.senderId != currentUserId) {
              _scheduleMarkAsRead();
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
          // Gap-fill on every successful (re)connect so missed messages are
          // picked up regardless of whether the closed/error state was observed.
          // The _messages.isNotEmpty guard skips the initial open (loadMessages
          // handles that path already).
          if (status == RealtimeSubscribeStatus.subscribed &&
              _messages.isNotEmpty) {
            _fillGap();
          }
        });
  }

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void dispose() {
    _readDebounce?.cancel();
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
