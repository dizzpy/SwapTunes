import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/repositories/messaging_repository.dart';

/// Manages conversation list state and Supabase Realtime inbox subscriptions.
///
/// Subscribe/unsubscribe lifecycle is tied to the screen:
/// call [subscribeToInboxUpdates] in initState, dispose will clean up.
///
/// Two Realtime channels are used — one for each user_one/user_two position —
/// so inbox updates arrive regardless of which side of the pair the user is on.
class ChatsListViewmodel extends ChangeNotifier {
  final MessagingRepository _repository;
  final String _currentUserId;

  List<ChatConversationModel> _conversations = [];
  bool _isLoading = false;
  bool _isReconnecting = false;
  String? _error;

  RealtimeChannel? _channelAsUserOne;
  RealtimeChannel? _channelAsUserTwo;

  ChatsListViewmodel(this._repository, this._currentUserId);

  List<ChatConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  bool get isReconnecting => _isReconnecting;
  String? get error => _error;

  // ── Data ───────────────────────────────────────────────

  /// Loads conversations with a stale-while-revalidate strategy:
  ///
  /// 1. On first open, renders any cached conversations instantly (no shimmer
  ///    because the screen only shows it when the list is empty).
  /// 2. Fetches fresh conversations from the API in the background.
  /// 3. Updates the UI silently with the fresh data.
  Future<void> loadConversations() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Phase 1 — show stale cache instantly on first open.
    if (_conversations.isEmpty) {
      final stale = await _repository.getCachedConversationsStale();
      if (stale != null && stale.isNotEmpty) {
        _conversations = stale;
        notifyListeners();
      }
    }

    // Phase 2 — background refresh from the API.
    try {
      _conversations = await _repository.getConversations(forceRefresh: true);
    } catch (e) {
      if (_conversations.isEmpty) _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatConversationModel?> startConversation(
    String recipientId, {
    String? collabId,
  }) async {
    try {
      return await _repository.startConversation(
        recipientId,
        collabId: collabId,
      );
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  /// Optimistically removes [conversationId] from the list, then deletes via API.
  /// Returns true on success, false on failure (also restores the list).
  Future<bool> deleteConversation(String conversationId) async {
    final backup = List<ChatConversationModel>.from(_conversations);
    _conversations = _conversations.where((c) => c.id != conversationId).toList();
    notifyListeners();

    try {
      await _repository.deleteConversation(conversationId);
      return true;
    } catch (e) {
      _conversations = backup;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Realtime ───────────────────────────────────────────

  /// Subscribes to conversation UPDATE events for inbox re-sorting.
  ///
  /// Two channels are needed because the user may be user_one or user_two
  /// in any given conversation. Missing either channel causes silent gaps.
  void subscribeToInboxUpdates() {
    final supabase = Supabase.instance.client;

    _channelAsUserOne = supabase
        .channel('inbox_one:$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_one_id',
            value: _currentUserId,
          ),
          callback: (_) => loadConversations(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_one_id',
            value: _currentUserId,
          ),
          callback: (_) => loadConversations(),
        )
        .subscribe((status, _) {
          final reconnecting = status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.channelError;
          if (_isReconnecting != reconnecting) {
            _isReconnecting = reconnecting;
            notifyListeners();
          }
        });

    _channelAsUserTwo = supabase
        .channel('inbox_two:$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_two_id',
            value: _currentUserId,
          ),
          callback: (_) => loadConversations(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_two_id',
            value: _currentUserId,
          ),
          callback: (_) => loadConversations(),
        )
        .subscribe();
  }

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void dispose() {
    if (_channelAsUserOne != null) {
      Supabase.instance.client.removeChannel(_channelAsUserOne!);
    }
    if (_channelAsUserTwo != null) {
      Supabase.instance.client.removeChannel(_channelAsUserTwo!);
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) return 'Session expired. Please log in again.';
    return e.toString();
  }
}
