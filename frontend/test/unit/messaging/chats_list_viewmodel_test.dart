import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/messaging/presentation/viewmodels/chats_list_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMessagingRepository mockRepo;
  late ChatsListViewmodel vm;

  setUp(() {
    mockRepo = MockMessagingRepository();
    vm = ChatsListViewmodel(mockRepo, 'user-1');
  });

  tearDown(() => vm.dispose());

  // ── loadConversations ──────────────────────────────────────────────────

  group('loadConversations', () {
    test('success — conversations populated', () async {
      when(() => mockRepo.getConversations(
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tConversation]);

      await vm.loadConversations();

      expect(vm.conversations.length, 1);
      expect(vm.conversations.first.id, 'convo-1');
      expect(vm.isLoading, false);
      expect(vm.error, isNull);
    });

    test('failure — error set, conversations list stays empty', () async {
      when(() => mockRepo.getConversations(
            forceRefresh: any(named: 'forceRefresh'),
          )).thenThrow(Exception('Network error'));

      await vm.loadConversations();

      expect(vm.conversations, isEmpty);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, false);
    });

    test('concurrent guard — second call while loading is a no-op', () async {
      when(() => mockRepo.getConversations(
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tConversation]);

      final f1 = vm.loadConversations();
      final f2 = vm.loadConversations(); // ignored — already loading
      await Future.wait([f1, f2]);

      verify(() => mockRepo.getConversations(
            forceRefresh: any(named: 'forceRefresh'),
          )).called(1);
    });
  });

  // ── deleteConversation ─────────────────────────────────────────────────

  group('deleteConversation', () {
    setUp(() async {
      when(() => mockRepo.getConversations(
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => [tConversation]);
      await vm.loadConversations();
    });

    test('optimistic — conversation removed before API responds', () async {
      final completer = Completer<void>();
      when(() => mockRepo.deleteConversation('convo-1'))
          .thenAnswer((_) => completer.future);

      final future = vm.deleteConversation('convo-1');

      expect(vm.conversations, isEmpty);

      completer.complete();
      await future;
    });

    test('failure — conversation list restored on API error', () async {
      when(() => mockRepo.deleteConversation('convo-1'))
          .thenThrow(Exception('Delete failed'));

      await vm.deleteConversation('convo-1');

      expect(vm.conversations.length, 1);
      expect(vm.conversations.first.id, 'convo-1');
    });

    test('returns true on success', () async {
      when(() => mockRepo.deleteConversation('convo-1'))
          .thenAnswer((_) async {});

      final result = await vm.deleteConversation('convo-1');

      expect(result, true);
    });

    test('returns false on failure', () async {
      when(() => mockRepo.deleteConversation('convo-1'))
          .thenThrow(Exception('Delete failed'));

      final result = await vm.deleteConversation('convo-1');

      expect(result, false);
    });
  });
}
