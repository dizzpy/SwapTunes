import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/core/services/storage_service.dart';
import 'package:swaptune/features/messaging/data/models/cached_conversation.dart';
import 'package:swaptune/features/messaging/data/models/cached_messages.dart';
import 'package:swaptune/features/messaging/data/repositories/messaging_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

// ── Local mock (StorageService is a concrete class, not injected elsewhere) ──
class MockStorageService extends Mock implements StorageService {}

// ── Helper to build the cache JSON for a conversation ─────────────────────
String _buildConversationJson(
    String id,
    String participantId,
    String participantName,
    String? avatarUrl,
    bool isOnline,
    String lastMessage,
    DateTime lastMessageAt,
    int unreadCount,
    ) =>
    jsonEncode([
      {
        'id': id,
        'participant_id': participantId,
        'participant_name': participantName,
        'participant_avatar_url': avatarUrl,
        'is_online': isOnline,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.toIso8601String(),
        'unread_count': unreadCount,
      }
    ]);

void main() {
  late Directory tempDir;
  late Isar isar;
  late MockMessagingRemoteDatasource mockDatasource;
  late MockStorageService mockStorage;
  late MessagingRepository repository;

  // API-format response from GET /conversations (the shape fromApiJson expects)
  final apiConversation = {
    'id': 'convo-1',
    'user_one': {'id': 'user-1', 'full_name': 'Test User', 'avatar_url': null},
    'user_two': {
      'id': 'user-2',
      'full_name': 'Other User',
      'avatar_url': null
    },
    'last_message': 'Hello!',
    'last_message_at': '2024-01-01T12:00:00.000',
    'unread_count': 0,
  };

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_messaging_test_');
    isar = await Isar.open(
      [CachedConversationSchema, CachedMessagesSchema],
      directory: tempDir.path,
      name: 'messaging_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    mockDatasource = MockMessagingRemoteDatasource();
    mockStorage = MockStorageService();
    when(() => mockStorage.getUserId()).thenReturn('user-1');
    repository = MessagingRepository(mockDatasource, mockStorage, isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Conversations cache ────────────────────────────────────────────────

  test('fresh conversations cache — served without calling datasource',
      () async {
    final row = CachedConversation()
      ..userId = 'user-1'
      ..contentJson = _buildConversationJson(
        tConversation.id,
        tConversation.participantId,
        tConversation.participantName,
        tConversation.participantAvatarUrl,
        tConversation.isOnline,
        tConversation.lastMessage,
        tConversation.lastMessageAt,
        tConversation.unreadCount,
      )
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedConversations.put(row));

    final result = await repository.getConversations();

    verifyNever(() => mockDatasource.getConversations());
    expect(result.length, 1);
    expect(result.first.id, 'convo-1');
  });

  test('empty conversations cache — calls datasource and writes to Isar',
      () async {
    when(() => mockDatasource.getConversations())
        .thenAnswer((_) async => [apiConversation]);

    final result = await repository.getConversations();

    verify(() => mockDatasource.getConversations()).called(1);
    expect(result.length, 1);
    expect(result.first.id, 'convo-1');

    final cached = await isar.cachedConversations.where().findAll();
    expect(cached.length, 1);
    expect(cached.first.userId, 'user-1');
  });

  test('stale conversations cache (> 2 min) — calls datasource and refreshes Isar',
      () async {
    // Cache is 3 minutes old — exceeds the 2-min TTL
    final row = CachedConversation()
      ..userId = 'user-1'
      ..contentJson = _buildConversationJson(
        'stale-convo', 'user-2', 'Other User', null, false, 'Old', DateTime.now(), 0)
      ..cachedAt = DateTime.now().subtract(const Duration(minutes: 3));
    await isar.writeTxn(() => isar.cachedConversations.put(row));

    when(() => mockDatasource.getConversations())
        .thenAnswer((_) async => [apiConversation]);

    final result = await repository.getConversations();

    verify(() => mockDatasource.getConversations()).called(1);
    expect(result.first.id, 'convo-1'); // fresh data returned
  });

  test('API failure + stale cache — returns stale data silently', () async {
    final row = CachedConversation()
      ..userId = 'user-1'
      ..contentJson = _buildConversationJson(
        'stale-convo', 'user-2', 'Other User', null, false, 'Stale', DateTime.now(), 0)
      ..cachedAt = DateTime.now().subtract(const Duration(minutes: 3));
    await isar.writeTxn(() => isar.cachedConversations.put(row));

    when(() => mockDatasource.getConversations())
        .thenThrow(Exception('Network error'));

    final result = await repository.getConversations();

    expect(result.length, 1);
    expect(result.first.id, 'stale-convo');
  });

  test('forceRefresh:true — bypasses fresh cache and calls datasource',
      () async {
    // Pre-populate with a FRESH cache row (within TTL)
    final row = CachedConversation()
      ..userId = 'user-1'
      ..contentJson = _buildConversationJson(
        'cached-convo', 'user-2', 'Old', null, false, 'Old', DateTime.now(), 0)
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedConversations.put(row));

    when(() => mockDatasource.getConversations())
        .thenAnswer((_) async => [apiConversation]);

    final result = await repository.getConversations(forceRefresh: true);

    verify(() => mockDatasource.getConversations()).called(1);
    expect(result.first.id, 'convo-1'); // fresh, not 'cached-convo'
  });

  test('deleteConversation — cache row deleted entirely', () async {
    // Pre-populate cache
    final row = CachedConversation()
      ..userId = 'user-1'
      ..contentJson = _buildConversationJson(
        tConversation.id,
        tConversation.participantId,
        tConversation.participantName,
        tConversation.participantAvatarUrl,
        tConversation.isOnline,
        tConversation.lastMessage,
        tConversation.lastMessageAt,
        tConversation.unreadCount,
      )
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedConversations.put(row));

    when(() => mockDatasource.deleteConversation('convo-1'))
        .thenAnswer((_) async {});

    await repository.deleteConversation('convo-1');

    final cached = await isar.cachedConversations.where().findAll();
    expect(cached, isEmpty);
  });

  // ── Messages cache ─────────────────────────────────────────────────────

  test('fresh messages cache — served without calling datasource', () async {
    final row = CachedMessages()
      ..conversationId = 'convo-1'
      ..contentJson = jsonEncode([tMessage.toJson()])
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedMessages.put(row));

    final result = await repository.getMessages('convo-1');

    verifyNever(() => mockDatasource.getMessages(
          any(),
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ));
    expect(result.length, 1);
    expect(result.first.id, 'msg-1');
  });

  test('empty messages cache — calls datasource and writes to Isar', () async {
    when(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tMessage]);

    final result = await repository.getMessages('convo-1');

    verify(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).called(1);
    expect(result.length, 1);

    final cached = await isar.cachedMessages.where().findAll();
    expect(cached.length, 1);
    expect(cached.first.conversationId, 'convo-1');
  });

  test('stale messages cache (> 1 min) — calls datasource and refreshes Isar',
      () async {
    // Cache is 2 minutes old — exceeds the 1-min TTL
    final row = CachedMessages()
      ..conversationId = 'convo-1'
      ..contentJson = jsonEncode([tMessage.toJson()])
      ..cachedAt = DateTime.now().subtract(const Duration(minutes: 2));
    await isar.writeTxn(() => isar.cachedMessages.put(row));

    final freshMsg = makeMessage(id: 'msg-new');
    when(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [freshMsg]);

    final result = await repository.getMessages('convo-1');

    verify(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).called(1);
    expect(result.first.id, 'msg-new');
  });

  test('API failure + stale messages cache — returns stale data silently',
      () async {
    final row = CachedMessages()
      ..conversationId = 'convo-1'
      ..contentJson = jsonEncode([tMessage.toJson()])
      ..cachedAt = DateTime.now().subtract(const Duration(minutes: 2));
    await isar.writeTxn(() => isar.cachedMessages.put(row));

    when(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).thenThrow(Exception('Network error'));

    final result = await repository.getMessages('convo-1');

    expect(result.length, 1);
    expect(result.first.id, 'msg-1');
  });

  test('sendMessage — invalidates messages cache for that conversation',
      () async {
    // Pre-populate cache
    final row = CachedMessages()
      ..conversationId = 'convo-1'
      ..contentJson = jsonEncode([tMessage.toJson()])
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedMessages.put(row));

    when(() => mockDatasource.sendMessage('convo-1', any()))
        .thenAnswer((_) async => tMessage);

    await repository.sendMessage('convo-1', 'Hello!');

    final cached = await isar.cachedMessages.where().findAll();
    expect(cached, isEmpty);
  });

  test('before != null — always calls datasource, result never cached',
      () async {
    // Pre-populate with fresh cache
    final row = CachedMessages()
      ..conversationId = 'convo-1'
      ..contentJson = jsonEncode([tMessage.toJson()])
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedMessages.put(row));

    when(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tMessage]);

    // Load page 2 (before != null → bypasses cache)
    await repository.getMessages('convo-1', before: DateTime.now());

    verify(() => mockDatasource.getMessages(
          'convo-1',
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        )).called(1);
  });
}
