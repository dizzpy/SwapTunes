import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Manages notification list state, pagination, and Supabase Realtime badge updates.
///
/// Lifecycle:
///   1. Instantiate in FeedScreen.initState() with repository + currentUserId.
///   2. Call loadNotifications() + subscribeToNotifications() via addPostFrameCallback.
///   3. dispose() cleans up the Realtime channel.
class NotificationViewmodel extends ChangeNotifier {
  final NotificationRepository _repository;
  final String _currentUserId;

  static const int _pageSize = 20;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  RealtimeChannel? _channel;

  NotificationViewmodel(this._repository, this._currentUserId);

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ── Data ───────────────────────────────────────────────

  /// Loads the first page, replacing any existing list.
  Future<void> loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getNotifications(
        page: 0,
        limit: _pageSize,
      );
      _notifications = results;
      _hasMore = results.length == _pageSize;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page to the existing list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final results = await _repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );
      _page = nextPage;
      _notifications = [..._notifications, ...results];
      _hasMore = results.length == _pageSize;
    } catch (_) {
      // silently ignore load-more errors
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Optimistically marks every notification in a group as read.
  Future<void> markGroupAsRead(List<String> notificationIds) async {
    final unreadIds = notificationIds
        .where((id) => _notifications.any((n) => n.id == id && !n.isRead))
        .toList();
    if (unreadIds.isEmpty) return;

    _notifications = _notifications.map((n) {
      return unreadIds.contains(n.id) ? n.markRead() : n;
    }).toList();
    _unreadCount = (_unreadCount - unreadIds.length).clamp(0, _unreadCount);
    notifyListeners();

    // Fire-and-forget each mark-read call
    for (final id in unreadIds) {
      _repository.markAsRead(id).catchError((_) {});
    }
  }

  /// Optimistically removes the group from the list, then calls the API.
  Future<void> deleteNotification(List<String> notificationIds) async {
    final deletedUnread = _notifications
        .where((n) => notificationIds.contains(n.id) && !n.isRead)
        .length;
    _notifications =
        _notifications.where((n) => !notificationIds.contains(n.id)).toList();
    _unreadCount = (_unreadCount - deletedUnread).clamp(0, _unreadCount);
    notifyListeners();

    for (final id in notificationIds) {
      _repository.deleteNotification(id).catchError((_) {});
    }
  }

  /// Optimistically marks all notifications as read, then calls the API.
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    _notifications = _notifications.map((n) => n.markRead()).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      await loadNotifications();
    }
  }

  // ── Realtime ───────────────────────────────────────────

  void subscribeToNotifications() {
    _channel = Supabase.instance.client
        .channel('notifications:$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _currentUserId,
          ),
          callback: (_) {
            _unreadCount++;
            notifyListeners();
            // Refresh page 0 to pick up the new notification at the top
            loadNotifications();
          },
        )
        .subscribe();
  }

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
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
