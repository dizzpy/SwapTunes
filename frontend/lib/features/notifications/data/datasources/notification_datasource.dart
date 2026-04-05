import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

/// Remote datasource for all notification API calls.
class NotificationDatasource {
  final ApiClient _client;

  NotificationDatasource(this._client);

  Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    final data = await _client.get(
      ApiConstants.notifications,
      queryParams: {'page': '$page', 'limit': '$limit'},
    ) as List;
    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.patch('${ApiConstants.notifications}/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _client.patch(ApiConstants.notificationsMarkAllRead);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.delete('${ApiConstants.notifications}/$notificationId');
  }
}
