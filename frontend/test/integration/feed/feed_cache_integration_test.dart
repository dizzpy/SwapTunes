import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/feed/data/models/cached_post.dart';
import 'package:swaptune/features/feed/data/repositories/feed_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late MockFeedRemoteDatasource mockDatasource;
  late FeedRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_feed_test_');
    isar = await Isar.open(
      [CachedPostSchema],
      directory: tempDir.path,
      name: 'feed_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    mockDatasource = MockFeedRemoteDatasource();
    repository = FeedRepository(mockDatasource, isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Cache hit ──────────────────────────────────────────────────────────

  test('fresh cache — returns posts without calling the datasource', () async {
    // Pre-populate Isar with fresh cached data
    final now = DateTime.now();
    final row = CachedPost()
      ..postId = 'post-1'
      ..page = 1
      ..contentJson = '{"id":"post-1","user_id":"user-1","content":"Cached",'
          '"image_url":null,"likes_count":0,"comments_count":0,"is_liked":false,'
          '"created_at":"2024-01-01T00:00:00.000","user":{"username":"u",'
          '"full_name":"U","avatar_url":null,"is_verified":false}}'
      ..cachedAt = now;

    await isar.writeTxn(() => isar.cachedPosts.put(row));

    final posts = await repository.getFeed(page: 1, forceRefresh: false);

    verifyNever(() => mockDatasource.getFeed(page: any(named: 'page')));
    expect(posts.length, 1);
    expect(posts.first.id, 'post-1');
  });

  // ── Cache miss ─────────────────────────────────────────────────────────

  test('empty cache — calls datasource and stores result in Isar', () async {
    when(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tPost]);

    final posts = await repository.getFeed(page: 1, forceRefresh: false);

    verify(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).called(1);
    expect(posts.length, 1);

    // Isar should now have the cached entry
    final cached = await isar.cachedPosts.where().findAll();
    expect(cached.length, 1);
    expect(cached.first.postId, tPost.id);
  });

  // ── Stale cache ────────────────────────────────────────────────────────

  test('stale cache (> 5 min) — calls datasource and refreshes Isar',
      () async {
    // Pre-populate with data that is 10 minutes old
    final staleTime = DateTime.now().subtract(const Duration(minutes: 10));
    final row = CachedPost()
      ..postId = 'stale-post'
      ..page = 1
      ..contentJson = '{"id":"stale-post","user_id":"user-1","content":"Stale",'
          '"image_url":null,"likes_count":0,"comments_count":0,"is_liked":false,'
          '"created_at":"2024-01-01T00:00:00.000","user":{"username":"u",'
          '"full_name":"U","avatar_url":null,"is_verified":false}}'
      ..cachedAt = staleTime;
    await isar.writeTxn(() => isar.cachedPosts.put(row));

    when(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tPost]);

    final posts = await repository.getFeed(page: 1, forceRefresh: false);

    verify(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).called(1);
    expect(posts.first.id, tPost.id); // fresh data returned
  });

  // ── API failure + stale fallback ───────────────────────────────────────

  test('API failure — returns stale cache silently without throwing', () async {
    // Pre-populate with stale data
    final staleTime = DateTime.now().subtract(const Duration(minutes: 10));
    final row = CachedPost()
      ..postId = 'stale-post'
      ..page = 1
      ..contentJson = '{"id":"stale-post","user_id":"user-1","content":"Stale",'
          '"image_url":null,"likes_count":0,"comments_count":0,"is_liked":false,'
          '"created_at":"2024-01-01T00:00:00.000","user":{"username":"u",'
          '"full_name":"U","avatar_url":null,"is_verified":false}}'
      ..cachedAt = staleTime;
    await isar.writeTxn(() => isar.cachedPosts.put(row));

    when(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenThrow(Exception('Network error'));

    final posts = await repository.getFeed(page: 1, forceRefresh: false);

    // Stale data returned instead of throwing
    expect(posts.length, 1);
    expect(posts.first.id, 'stale-post');
  });

  // ── forceRefresh bypasses fresh cache ──────────────────────────────────

  test('forceRefresh:true — bypasses fresh cache and calls datasource',
      () async {
    // Pre-populate with FRESH data (within TTL)
    final now = DateTime.now();
    final row = CachedPost()
      ..postId = 'cached-post'
      ..page = 1
      ..contentJson = '{"id":"cached-post","user_id":"user-1","content":"Old",'
          '"image_url":null,"likes_count":0,"comments_count":0,"is_liked":false,'
          '"created_at":"2024-01-01T00:00:00.000","user":{"username":"u",'
          '"full_name":"U","avatar_url":null,"is_verified":false}}'
      ..cachedAt = now;
    await isar.writeTxn(() => isar.cachedPosts.put(row));

    when(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tPost]);

    final posts = await repository.getFeed(page: 1, forceRefresh: true);

    // Datasource was called despite fresh cache
    verify(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).called(1);
    expect(posts.first.id, tPost.id);
  });

  // ── No stale fallback for page > 1 ────────────────────────────────────

  test('page > 1 — always calls datasource, never cached', () async {
    when(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [tPost]);

    await repository.getFeed(page: 2, forceRefresh: false);

    verify(() => mockDatasource.getFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).called(1);
  });
}
