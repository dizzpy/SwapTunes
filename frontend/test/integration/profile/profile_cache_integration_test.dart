import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/core/network/api_client.dart';
import 'package:swaptune/features/profile/data/models/cached_profile.dart';
import 'package:swaptune/features/profile/data/models/cached_user_post.dart';
import 'package:swaptune/features/profile/data/repositories/profile_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

// ── ApiClient mock (needed for ProfileRepository constructor) ──────────────
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late Directory tempDir;
  late Isar isar;
  late MockProfileRemoteDatasource mockDatasource;
  late MockApiClient mockClient;
  late ProfileRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_profile_test_');
    isar = await Isar.open(
      [CachedProfileSchema, CachedUserPostSchema],
      directory: tempDir.path,
      name: 'profile_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    mockDatasource = MockProfileRemoteDatasource();
    mockClient = MockApiClient();
    repository = ProfileRepository(mockClient, mockDatasource, isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Profile cache hit ──────────────────────────────────────────────────

  test('fresh profile cache — returns profile without calling datasource',
      () async {
    final profileJson = jsonEncode({
      'id': 'user-1',
      'full_name': 'Test User',
      'username': 'testuser',
      'bio': null,
      'avatar_url': null,
      'cover_url': null,
      'user_type': 'listener',
      'is_verified': false,
      'spotify_connected': false,
      'created_at': '2024-01-01T00:00:00.000',
      'username_changed_at': null,
      'genres': ['pop'],
      'stats': {
        'followers': 100,
        'following': 50,
        'posts': 10,
        'playlists': 3,
        'collabs': 1,
      },
      'is_following': false,
      'creator_profiles': [],
    });

    final row = CachedProfile()
      ..username = 'testuser'
      ..contentJson = profileJson
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedProfiles.put(row));

    final profile = await repository.getUserProfile('testuser');

    verifyNever(() => mockDatasource.getUserProfile(any()));
    expect(profile.username, 'testuser');
    expect(profile.id, 'user-1');
  });

  // ── Profile cache miss ─────────────────────────────────────────────────

  test('empty profile cache — calls datasource and stores in Isar', () async {
    when(() => mockDatasource.getUserProfile('testuser'))
        .thenAnswer((_) async => tProfile);

    final profile =
        await repository.getUserProfile('testuser', forceRefresh: false);

    verify(() => mockDatasource.getUserProfile('testuser')).called(1);
    expect(profile.username, 'testuser');

    // Isar should now have the entry
    final cached = await isar.cachedProfiles.where().findAll();
    expect(cached.length, 1);
    expect(cached.first.username, 'testuser');
  });

  // ── Profile stale cache ────────────────────────────────────────────────

  test('stale profile cache — calls datasource and refreshes Isar', () async {
    final staleRow = CachedProfile()
      ..username = 'testuser'
      ..contentJson = '{"id":"old","full_name":"Old","username":"testuser",'
          '"bio":null,"avatar_url":null,"cover_url":null,"user_type":"listener",'
          '"is_verified":false,"spotify_connected":false,'
          '"created_at":"2024-01-01T00:00:00.000","username_changed_at":null,'
          '"genres":[],"stats":{"followers":0,"following":0,"posts":0,'
          '"playlists":0,"collabs":0},"is_following":null,"creator_profiles":[]}'
      ..cachedAt = DateTime.now().subtract(const Duration(minutes: 10));
    await isar.writeTxn(() => isar.cachedProfiles.put(staleRow));

    when(() => mockDatasource.getUserProfile('testuser'))
        .thenAnswer((_) async => tProfile);

    final profile = await repository.getUserProfile('testuser');

    verify(() => mockDatasource.getUserProfile('testuser')).called(1);
    expect(profile.fullName, tProfile.fullName);
  });

  // ── forceRefresh bypasses fresh profile cache ──────────────────────────

  test('forceRefresh:true — bypasses fresh cache and calls datasource',
      () async {
    // Fresh entry in Isar
    final row = CachedProfile()
      ..username = 'testuser'
      ..contentJson = '{}'
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedProfiles.put(row));

    when(() => mockDatasource.getUserProfile('testuser'))
        .thenAnswer((_) async => tProfile);

    await repository.getUserProfile('testuser', forceRefresh: true);

    verify(() => mockDatasource.getUserProfile('testuser')).called(1);
  });

  // ── User posts cache hit ───────────────────────────────────────────────

  test('fresh user posts cache — returns posts without calling datasource',
      () async {
    final postsJson = jsonEncode([
      {
        'id': 'post-1',
        'user_id': 'user-1',
        'content': 'Cached post',
        'image_url': null,
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
        'created_at': '2024-01-01T00:00:00.000',
        'user': {
          'username': 'testuser',
          'full_name': 'Test User',
          'avatar_url': null,
          'is_verified': false,
        },
      }
    ]);

    final row = CachedUserPost()
      ..userId = 'user-1'
      ..contentJson = postsJson
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedUserPosts.put(row));

    final posts = await repository.getUserPosts('user-1', forceRefresh: false);

    verifyNever(() => mockDatasource.getUserPosts(any()));
    expect(posts.length, 1);
    expect(posts.first.id, 'post-1');
  });

  // ── User posts cache miss ──────────────────────────────────────────────

  test('empty user posts cache — calls datasource and stores in Isar',
      () async {
    when(() => mockDatasource.getUserPosts('user-1', page: any(named: 'page')))
        .thenAnswer((_) async => [tPost]);

    final posts = await repository.getUserPosts('user-1', forceRefresh: false);

    verify(() =>
            mockDatasource.getUserPosts('user-1', page: any(named: 'page')))
        .called(1);
    expect(posts.length, 1);

    final cached = await isar.cachedUserPosts.where().findAll();
    expect(cached.length, 1);
    expect(cached.first.userId, 'user-1');
  });

  // ── User posts forceRefresh ────────────────────────────────────────────

  test('forceRefresh:true on user posts — bypasses fresh cache', () async {
    // Fresh entry
    final row = CachedUserPost()
      ..userId = 'user-1'
      ..contentJson = '[]'
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedUserPosts.put(row));

    when(() => mockDatasource.getUserPosts('user-1', page: any(named: 'page')))
        .thenAnswer((_) async => [tPost]);

    await repository.getUserPosts('user-1', forceRefresh: true);

    verify(() =>
            mockDatasource.getUserPosts('user-1', page: any(named: 'page')))
        .called(1);
  });

  // ── invalidateCache ────────────────────────────────────────────────────

  test('invalidateCache removes profile from Isar', () async {
    final row = CachedProfile()
      ..username = 'testuser'
      ..contentJson = '{}'
      ..cachedAt = DateTime.now();
    await isar.writeTxn(() => isar.cachedProfiles.put(row));

    await repository.invalidateCache('testuser');

    final cached = await isar.cachedProfiles.where().findAll();
    expect(cached, isEmpty);
  });
}
