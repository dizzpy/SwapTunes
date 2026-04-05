import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/feed/data/models/comment_model.dart';
import 'package:swaptune/features/feed/data/models/post_model.dart';
import 'package:swaptune/features/feed/presentation/viewmodels/feed_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFeedRepository mockRepo;
  late FeedViewmodel vm;

  setUp(() {
    mockRepo = MockFeedRepository();
    vm = FeedViewmodel(mockRepo);
  });

  tearDown(() => vm.dispose());

  // ── loadFeed ───────────────────────────────────────────────────────────

  group('loadFeed', () {
    test('happy path — posts loaded, hasMore true when full page', () async {
      final posts = List.generate(20, (i) => makePost(id: 'post-$i'));
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => posts);

      await vm.loadFeed();

      expect(vm.posts.length, 20);
      expect(vm.isLoading, false);
      expect(vm.hasMore, true);
      expect(vm.feedError, isNull);
    });

    test('hasMore is false when response is less than page size', () async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);

      await vm.loadFeed();

      expect(vm.hasMore, false);
    });

    test('error path — feedError set, posts empty', () async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenThrow(Exception('Network error'));

      await vm.loadFeed();

      expect(vm.feedError, isNotNull);
      expect(vm.posts, isEmpty);
      expect(vm.isLoading, false);
    });

    test('guard — concurrent call while loading is ignored', () async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);

      final f1 = vm.loadFeed();
      final f2 = vm.loadFeed(); // no-op — already loading
      await Future.wait([f1, f2]);

      verify(() => mockRepo.getFeed(page: 1, forceRefresh: false)).called(1);
    });
  });

  // ── loadMore ───────────────────────────────────────────────────────────

  group('loadMore', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer(
              (_) async => List.generate(20, (i) => makePost(id: 'post-$i')));
      await vm.loadFeed();
    });

    test('happy path — appends posts to existing list', () async {
      when(() => mockRepo.getFeed(page: 2, forceRefresh: false))
          .thenAnswer((_) async => [makePost(id: 'post-20')]);

      await vm.loadMore();

      expect(vm.posts.length, 21);
    });

    test('guard — no-op when hasMore is false', () async {
      when(() => mockRepo.getFeed(page: 2, forceRefresh: false))
          .thenAnswer((_) async => []); // empty → hasMore becomes false
      await vm.loadMore();

      await vm.loadMore(); // ignored

      verify(() => mockRepo.getFeed(page: 2, forceRefresh: false)).called(1);
    });

    test('error is silent — existing posts remain unchanged', () async {
      when(() => mockRepo.getFeed(page: 2, forceRefresh: false))
          .thenThrow(Exception('Network error'));

      await vm.loadMore();

      expect(vm.posts.length, 20);
      expect(vm.feedError, isNull);
    });
  });

  // ── createPost (optimistic UI) ─────────────────────────────────────────

  group('createPost', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
    });

    test('optimistic — placeholder inserted at index 0 before API responds',
        () async {
      final completer = Completer<PostModel>();
      when(() => mockRepo.createPost(any(), imageUrl: any(named: 'imageUrl')))
          .thenAnswer((_) => completer.future);

      vm.createPost(
        content: 'New post',
        userId: 'user-1',
        authorUsername: 'testuser',
        authorFullName: 'Test User',
      );

      // Check state before API responds
      expect(vm.posts.length, 2);
      expect(vm.posts.first.isUploading, true);
      expect(vm.posts.first.content, 'New post');

      completer.complete(makePost(id: 'post-new', content: 'New post'));
      await Future.delayed(Duration.zero);
    });

    test('success — placeholder replaced with real post from server', () async {
      final newPost = makePost(id: 'post-new', content: 'New post');
      when(() => mockRepo.createPost(any(), imageUrl: any(named: 'imageUrl')))
          .thenAnswer((_) async => newPost);

      vm.createPost(
        content: 'New post',
        userId: 'user-1',
        authorUsername: 'testuser',
        authorFullName: 'Test User',
      );
      await Future.delayed(Duration.zero);

      expect(vm.posts.any((p) => p.isUploading), false);
      expect(vm.posts.any((p) => p.id == 'post-new'), true);
    });

    test('failure — placeholder removed, original list restored', () async {
      when(() => mockRepo.createPost(any(), imageUrl: any(named: 'imageUrl')))
          .thenThrow(Exception('Upload failed'));

      vm.createPost(
        content: 'New post',
        userId: 'user-1',
        authorUsername: 'testuser',
        authorFullName: 'Test User',
      );
      await Future.delayed(Duration.zero);

      expect(vm.posts.length, 1); // only original
      expect(vm.posts.any((p) => p.isUploading), false);
    });
  });

  // ── toggleLike debounce (3 required scenarios) ─────────────────────────

  group('toggleLike debounce', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
    });

    test('scenario 1 — rapid taps fire only 1 API call after debounce', () {
      when(() => mockRepo.likePost(any())).thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.toggleLike('post-1');
        vm.toggleLike('post-1');
        vm.toggleLike('post-1'); // odd number of taps → net liked

        verifyNever(() => mockRepo.likePost(any()));
        verifyNever(() => mockRepo.unlikePost(any()));

        fake.elapse(const Duration(milliseconds: 501));
        fake.flushMicrotasks();

        verify(() => mockRepo.likePost('post-1')).called(1);
        verifyNever(() => mockRepo.unlikePost(any()));
      });
    });

    test('scenario 2 — like then unlike within window fires 0 API calls', () {
      when(() => mockRepo.likePost(any())).thenAnswer((_) async {});
      when(() => mockRepo.unlikePost(any())).thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.toggleLike('post-1'); // like  (not liked → liked)
        vm.toggleLike('post-1'); // unlike (liked → not liked = original)

        fake.elapse(const Duration(milliseconds: 501));
        fake.flushMicrotasks();

        verifyNever(() => mockRepo.likePost(any()));
        verifyNever(() => mockRepo.unlikePost(any()));
      });
    });

    test('scenario 3 — single tap fires exactly 1 call, not before window',
        () {
      when(() => mockRepo.likePost(any())).thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.toggleLike('post-1');

        // Before debounce window — no call yet
        fake.elapse(const Duration(milliseconds: 499));
        verifyNever(() => mockRepo.likePost(any()));

        // After full window — exactly 1 call
        fake.elapse(const Duration(milliseconds: 2));
        fake.flushMicrotasks();

        verify(() => mockRepo.likePost('post-1')).called(1);
      });
    });

    test('failure — reverts isLiked and likesCount to original state', () {
      when(() => mockRepo.likePost(any()))
          .thenThrow(Exception('API failure'));

      fakeAsync((fake) {
        final originalLiked = vm.posts.first.isLiked; // false
        final originalCount = vm.posts.first.likesCount; // 5

        vm.toggleLike('post-1');

        // Optimistic update applied
        expect(vm.posts.first.isLiked, !originalLiked);
        expect(vm.posts.first.likesCount, originalCount + 1);

        fake.elapse(const Duration(milliseconds: 501));
        fake.flushMicrotasks();

        // Reverted on failure
        expect(vm.posts.first.isLiked, originalLiked);
        expect(vm.posts.first.likesCount, originalCount);
      });
    });
  });

  // ── updatePost (optimistic UI) ─────────────────────────────────────────

  group('updatePost', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
    });

    test('optimistic — content updated immediately before API responds',
        () async {
      final completer = Completer<PostModel>();
      when(() => mockRepo.updatePost(
            any(),
            content: any(named: 'content'),
            imageUrl: any(named: 'imageUrl'),
          )).thenAnswer((_) => completer.future);

      final future = vm.updatePost('post-1', 'Updated content');

      // Content updated before API responds
      expect(vm.posts.first.content, 'Updated content');

      completer.complete(makePost(content: 'Updated content'));
      await future;
    });

    test('success — returns true', () async {
      when(() => mockRepo.updatePost(
            any(),
            content: any(named: 'content'),
            imageUrl: any(named: 'imageUrl'),
          )).thenAnswer((_) async => makePost(content: 'Updated content'));

      final result = await vm.updatePost('post-1', 'Updated content');

      expect(result, true);
    });

    test('failure — reverts content and returns false', () async {
      final originalContent = vm.posts.first.content;

      when(() => mockRepo.updatePost(
            any(),
            content: any(named: 'content'),
            imageUrl: any(named: 'imageUrl'),
          )).thenThrow(Exception('Update failed'));

      final result = await vm.updatePost('post-1', 'Updated content');

      expect(result, false);
      expect(vm.posts.first.content, originalContent);
    });
  });

  // ── deletePost (optimistic UI) ─────────────────────────────────────────

  group('deletePost', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer(
              (_) async => [tPost, makePost(id: 'post-2', content: 'Second')]);
      await vm.loadFeed();
    });

    test('optimistic — post removed from list immediately', () async {
      final completer = Completer<void>();
      when(() => mockRepo.deletePost('post-1'))
          .thenAnswer((_) => completer.future);

      final future = vm.deletePost('post-1');

      // Removed before API responds
      expect(vm.posts.any((p) => p.id == 'post-1'), false);

      completer.complete();
      await future;
    });

    test('failure — post reinserted at original index', () async {
      when(() => mockRepo.deletePost('post-1'))
          .thenThrow(Exception('Delete failed'));

      await vm.deletePost('post-1');

      expect(vm.posts.any((p) => p.id == 'post-1'), true);
      expect(vm.posts.first.id, 'post-1');
    });
  });

  // ── hidePost (optimistic UI) ───────────────────────────────────────────

  group('hidePost', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
    });

    test('optimistic — post removed immediately', () async {
      final completer = Completer<void>();
      when(() => mockRepo.hidePost('post-1'))
          .thenAnswer((_) => completer.future);

      final future = vm.hidePost('post-1');

      expect(vm.posts, isEmpty);

      completer.complete();
      await future;
    });

    test('failure — post reinserted', () async {
      when(() => mockRepo.hidePost('post-1'))
          .thenThrow(Exception('Hide failed'));

      await vm.hidePost('post-1');

      expect(vm.posts.any((p) => p.id == 'post-1'), true);
    });
  });

  // ── reportPost ─────────────────────────────────────────────────────────

  group('reportPost', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
    });

    test('fire-and-forget — error is silent, no state change', () async {
      when(() => mockRepo.reportPost(any(), any()))
          .thenThrow(Exception('Report failed'));

      await vm.reportPost('post-1', 'inappropriate');

      expect(vm.feedError, isNull);
      expect(vm.posts.length, 1);
    });
  });

  // ── loadComments ───────────────────────────────────────────────────────

  group('loadComments', () {
    test('cache miss — shows loading then fetches and caches', () async {
      when(() => mockRepo.getComments('post-1'))
          .thenAnswer((_) async => [tComment]);

      await vm.loadComments('post-1');

      expect(vm.comments.length, 1);
      expect(vm.isCommentsLoading, false);
      expect(vm.commentError, isNull);
    });

    test('cache hit — serves cached data and still refreshes in background',
        () async {
      when(() => mockRepo.getComments('post-1'))
          .thenAnswer((_) async => [tComment]);

      await vm.loadComments('post-1'); // first load — caches
      await vm.loadComments('post-1'); // second load — uses cache first

      // API called twice (cache hit still refreshes in background)
      verify(() => mockRepo.getComments('post-1')).called(2);
      expect(vm.comments.length, 1);
    });

    test('error on first load — sets commentError', () async {
      when(() => mockRepo.getComments('post-1'))
          .thenThrow(Exception('Network error'));

      await vm.loadComments('post-1');

      expect(vm.commentError, isNotNull);
    });
  });

  // ── addComment (optimistic UI) ─────────────────────────────────────────

  group('addComment', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
      when(() => mockRepo.getComments('post-1'))
          .thenAnswer((_) async => []);
      await vm.loadComments('post-1');
    });

    test('optimistic — comment appended and commentsCount incremented',
        () async {
      final completer = Completer<CommentModel>();
      when(() => mockRepo.addComment('post-1', any()))
          .thenAnswer((_) => completer.future);

      final future = vm.addComment(
        'post-1',
        'Great post!',
        userId: 'user-1',
        authorUsername: 'testuser',
        authorFullName: 'Test User',
      );

      // Before API responds
      expect(vm.comments.length, 1);
      expect(vm.posts.first.commentsCount, tPost.commentsCount + 1);

      completer.complete(tComment);
      await future;
    });

    test('failure — comment removed and commentsCount decremented', () async {
      when(() => mockRepo.addComment('post-1', any()))
          .thenThrow(Exception('Failed to post'));

      await vm.addComment(
        'post-1',
        'Great post!',
        userId: 'user-1',
        authorUsername: 'testuser',
        authorFullName: 'Test User',
      );

      expect(vm.comments, isEmpty);
      expect(vm.posts.first.commentsCount, tPost.commentsCount);
    });
  });

  // ── deleteComment (optimistic UI) ──────────────────────────────────────

  group('deleteComment', () {
    setUp(() async {
      when(() => mockRepo.getFeed(page: 1, forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadFeed();
      when(() => mockRepo.getComments('post-1'))
          .thenAnswer((_) async => [tComment]);
      await vm.loadComments('post-1');
    });

    test('optimistic — comment removed and count decremented immediately',
        () async {
      final completer = Completer<void>();
      when(() => mockRepo.deleteComment('post-1', 'comment-1'))
          .thenAnswer((_) => completer.future);

      final future = vm.deleteComment('post-1', 'comment-1');

      // Before API responds
      expect(vm.comments, isEmpty);
      expect(vm.posts.first.commentsCount, tPost.commentsCount - 1);

      completer.complete();
      await future;
    });

    test('failure — comment reinserted and count restored', () async {
      when(() => mockRepo.deleteComment('post-1', 'comment-1'))
          .thenThrow(Exception('Delete failed'));

      await vm.deleteComment('post-1', 'comment-1');

      expect(vm.comments.length, 1);
      expect(vm.posts.first.commentsCount, tPost.commentsCount);
    });
  });

  // ── updateComment (optimistic UI) ──────────────────────────────────────

  group('updateComment', () {
    setUp(() async {
      when(() => mockRepo.getComments('post-1'))
          .thenAnswer((_) async => [tComment]);
      await vm.loadComments('post-1');
    });

    test('optimistic — content updated immediately before API responds',
        () async {
      final completer = Completer<CommentModel>();
      when(() => mockRepo.updateComment('post-1', 'comment-1', any()))
          .thenAnswer((_) => completer.future);

      final future =
          vm.updateComment('post-1', 'comment-1', 'Edited comment');

      // Updated before API responds
      expect(vm.comments.first.content, 'Edited comment');

      completer.complete(makeComment(content: 'Edited comment'));
      await future;
    });

    test('failure — reverts to original content', () async {
      final originalContent = vm.comments.first.content;

      when(() => mockRepo.updateComment('post-1', 'comment-1', any()))
          .thenThrow(Exception('Update failed'));

      await vm.updateComment('post-1', 'comment-1', 'Edited comment');

      expect(vm.comments.first.content, originalContent);
    });
  });

  // ── loadLikers ─────────────────────────────────────────────────────────

  group('loadLikers', () {
    test('happy path — likers list populated', () async {
      when(() => mockRepo.getLikers('post-1'))
          .thenAnswer((_) async => [tLiker]);

      await vm.loadLikers('post-1');

      expect(vm.likers.length, 1);
      expect(vm.isLikersLoading, false);
    });

    test('error — silent, empty list, no error surfaced', () async {
      when(() => mockRepo.getLikers('post-1'))
          .thenThrow(Exception('Network error'));

      await vm.loadLikers('post-1');

      expect(vm.likers, isEmpty);
      expect(vm.isLikersLoading, false);
    });
  });
}
