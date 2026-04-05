import '../../../../core/network/network_exceptions.dart';
import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';

/// Repository for notification operations.
///
/// Thin wrapper over [NotificationDatasource] — no Isar caching needed
/// since Supabase Realtime keeps the in-memory list up to date.
class NotificationRepository {
  final NotificationDatasource _datasource;

  NotificationRepository(this._datasource);

  Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      return await _datasource.getNotifications(page: page, limit: limit);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 'FETCH_NOTIFS_FAILED',
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _datasource.markAsRead(notificationId);
    } on ApiException {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _datasource.markAllAsRead();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _datasource.deleteNotification(notificationId);
    } on ApiException {
      rethrow;
    }
  }
}
