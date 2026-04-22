import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swaptune/features/notifications/presentation/viewmodels/notification_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockNotificationRepository mockRepo;
  late NotificationViewmodel vm;

  setUp(() {
    mockRepo = MockNotificationRepository();
    vm = NotificationViewmodel(mockRepo, 'user-1');
  });

  group('loadNotifications', () {
    test('loads list and calculates unread count', () async {
      final list = [
        makeNotification(id: 'n1', isRead: false),
        makeNotification(id: 'n2', isRead: true),
      ];
      when(
        () => mockRepo.getNotifications(page: 0, limit: 20),
      ).thenAnswer((_) async => list);

      await vm.loadNotifications();

      expect(vm.notifications.length, 2);
      expect(vm.unreadCount, 1);
      expect(vm.error, isNull);
    });

    test('sets error when repository throws', () async {
      when(
        () => mockRepo.getNotifications(page: 0, limit: 20),
      ).thenThrow(Exception('failed'));

      await vm.loadNotifications();

      expect(vm.error, isNotNull);
      expect(vm.isLoading, false);
    });
  });

  test('markGroupAsRead updates unread count and calls repo', () async {
    when(() => mockRepo.getNotifications(page: 0, limit: 20)).thenAnswer(
      (_) async => [
        makeNotification(id: 'n1', isRead: false),
        makeNotification(id: 'n2', isRead: false),
      ],
    );
    when(() => mockRepo.markAsRead(any())).thenAnswer((_) async {});

    await vm.loadNotifications();
    await vm.markGroupAsRead(['n1']);

    expect(vm.unreadCount, 1);
    verify(() => mockRepo.markAsRead('n1')).called(1);
  });

  test('markAllAsRead sets unread count to zero', () async {
    when(
      () => mockRepo.getNotifications(page: 0, limit: 20),
    ).thenAnswer((_) async => [makeNotification(id: 'n1', isRead: false)]);
    when(() => mockRepo.markAllAsRead()).thenAnswer((_) async {});

    await vm.loadNotifications();
    await vm.markAllAsRead();

    expect(vm.unreadCount, 0);
  });

  test('deleteNotification removes ids from list', () async {
    when(() => mockRepo.getNotifications(page: 0, limit: 20)).thenAnswer(
      (_) async => [
        makeNotification(id: 'n1', isRead: false),
        makeNotification(id: 'n2', isRead: true),
      ],
    );
    when(() => mockRepo.deleteNotification(any())).thenAnswer((_) async {});

    await vm.loadNotifications();
    await vm.deleteNotification(['n1']);

    expect(vm.notifications.map((e) => e.id), ['n2']);
    expect(vm.unreadCount, 0);
  });
}
