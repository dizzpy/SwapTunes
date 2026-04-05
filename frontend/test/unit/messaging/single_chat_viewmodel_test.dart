import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/messaging/data/models/message_model.dart';
import 'package:swaptune/features/messaging/presentation/viewmodels/single_chat_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMessagingRepository mockRepo;
  late SingleChatViewmodel vm;

  setUp(() {
    mockRepo = MockMessagingRepository();
    vm = SingleChatViewmodel(
      repository: mockRepo,
      conversationId: 'convo-1',
      currentUserId: 'user-1',
    );
  });

  tearDown(() => vm.dispose());

  // ── loadMessages ───────────────────────────────────────────────────────

  group('loadMessages', () {
    test('success — messages reversed to chronological order', () async {
      final msg1 = makeMessage(id: 'msg-1');
      final msg2 = makeMessage(id: 'msg-2');
      // API returns newest-first: [msg1, msg2]; reversed → [msg2, msg1]
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [msg1, msg2]);

      await vm.loadMessages();

      expect(vm.messages.first.id, 'msg-2');
      expect(vm.messages.last.id, 'msg-1');
      expect(vm.isLoading, false);
      expect(vm.error, isNull);
    });

    test('failure — error set, messages remain empty', () async {
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenThrow(Exception('Network error'));

      await vm.loadMessages();

      expect(vm.messages, isEmpty);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, false);
    });
  });

  // ── loadMore ───────────────────────────────────────────────────────────

  group('loadMore', () {
    setUp(() async {
      // Load initial full page so hasMore = true
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async =>
          List.generate(30, (i) => makeMessage(id: 'page1-$i')));
      await vm.loadMessages();
    });

    test('success — older messages prepended in chronological order', () async {
      final olderMsg = makeMessage(id: 'old-1');
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [olderMsg]);

      await vm.loadMore();

      expect(vm.messages.first.id, 'old-1');
    });

    test('hasMore set to false when response is less than pageSize', () async {
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tMessage]); // 1 < 30

      await vm.loadMore();

      expect(vm.hasMore, false);
    });
  });

  // ── sendMessage ────────────────────────────────────────────────────────

  group('sendMessage', () {
    test('optimistic — placeholder inserted before API responds', () async {
      final completer = Completer<MessageModel>();
      when(() => mockRepo.sendMessage('convo-1', any()))
          .thenAnswer((_) => completer.future);

      // ignore: unawaited_futures
      vm.sendMessage('Hello');

      expect(vm.messages.length, 1);
      expect(vm.messages.first.text, 'Hello');
      expect(vm.messages.first.id.startsWith('_temp_'), true);

      completer.complete(tMessage);
      await Future.delayed(Duration.zero);

      expect(vm.messages.first.id, tMessage.id);
    });

    test('failure — placeholder removed and error set', () async {
      when(() => mockRepo.sendMessage('convo-1', any()))
          .thenThrow(Exception('Send failed'));

      await vm.sendMessage('Hello');

      expect(vm.messages, isEmpty);
      expect(vm.error, isNotNull);
    });
  });

  // ── deleteMessage ──────────────────────────────────────────────────────

  group('deleteMessage', () {
    setUp(() async {
      when(() => mockRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tMessage]);
      // Default stub so dispose() doesn't throw when flushing pending deletes.
      when(() => mockRepo.deleteMessage(any(), any()))
          .thenAnswer((_) async {});
      await vm.loadMessages();
    });

    test('optimistic — isDeleted set to true immediately', () {
      vm.deleteMessage('msg-1');

      expect(vm.messages.first.isDeleted, true);
    });

    test('undoDeleteMessage — cancels timer and restores isDeleted to false', () {
      vm.deleteMessage('msg-1');
      vm.undoDeleteMessage('msg-1');

      expect(vm.messages.first.isDeleted, false);
    });

    test('after 5s window — API delete is called', () {
      when(() => mockRepo.deleteMessage(any(), any()))
          .thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.deleteMessage('msg-1');

        verifyNever(() => mockRepo.deleteMessage(any(), any()));

        fake.elapse(const Duration(seconds: 6));
        fake.flushMicrotasks();

        verify(() => mockRepo.deleteMessage('convo-1', 'msg-1')).called(1);
      });
    });

    test('dispose — pending deletes are flushed to API immediately', () async {
      // Use a dedicated VM so tearDown does not attempt a second dispose.
      final testRepo = MockMessagingRepository();
      when(() => testRepo.getMessages(
            'convo-1',
            before: any(named: 'before'),
            limit: any(named: 'limit'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tMessage]);
      when(() => testRepo.deleteMessage(any(), any()))
          .thenAnswer((_) async {});

      final testVm = SingleChatViewmodel(
        repository: testRepo,
        conversationId: 'convo-1',
        currentUserId: 'user-1',
      );
      await testVm.loadMessages();

      testVm.deleteMessage('msg-1');

      // Navigate away within the 5-second undo window
      testVm.dispose();
      await Future.delayed(Duration.zero);

      verify(() => testRepo.deleteMessage('convo-1', 'msg-1')).called(1);
    });
  });
}
