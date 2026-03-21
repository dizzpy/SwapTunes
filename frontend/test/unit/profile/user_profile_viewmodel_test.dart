import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/profile/presentation/viewmodels/user_profile_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockProfileRepository mockRepo;
  late UserProfileViewmodel vm;

  setUp(() {
    mockRepo = MockProfileRepository();
    vm = UserProfileViewmodel(mockRepo);
  });

  tearDown(() => vm.dispose());

  // ── loadProfile ────────────────────────────────────────────────────────

  group('loadProfile', () {
    test('happy path — profile loaded, isLoading false', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);

      await vm.loadProfile('testuser');

      expect(vm.profile, tProfile);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('error path — errorMessage set, profile null', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenThrow(Exception('Not found'));

      await vm.loadProfile('testuser');

      expect(vm.profile, isNull);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoading, false);
    });

    test('guard — second call while loading is ignored', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);

      final f1 = vm.loadProfile('testuser');
      final f2 = vm.loadProfile('testuser'); // no-op
      await Future.wait([f1, f2]);

      verify(() =>
              mockRepo.getUserProfile('testuser', forceRefresh: false))
          .called(1);
    });
  });

  // ── refresh ────────────────────────────────────────────────────────────

  group('refresh', () {
    setUp(() async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');
    });

    test('success — profile updated silently', () async {
      final updatedProfile = tProfile.copyWith(fullName: 'Updated Name');
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: true))
          .thenAnswer((_) async => updatedProfile);

      await vm.refresh('testuser');

      expect(vm.profile!.fullName, 'Updated Name');
    });

    test('failure — stale profile stays visible, no error shown', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: true))
          .thenThrow(Exception('Network error'));

      await vm.refresh('testuser');

      expect(vm.profile, tProfile); // unchanged
      expect(vm.errorMessage, isNull); // no error surfaced
    });
  });

  // ── applyLocalProfileEdit ──────────────────────────────────────────────

  group('applyLocalProfileEdit', () {
    setUp(() async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');
    });

    test('updates fields immediately in local state', () {
      vm.applyLocalProfileEdit(fullName: 'New Name', bio: 'New bio');

      expect(vm.profile!.fullName, 'New Name');
      expect(vm.profile!.bio, 'New bio');
    });

    test('null profile — no-op, does not throw', () {
      final emptyVm = UserProfileViewmodel(mockRepo);

      expect(() => emptyVm.applyLocalProfileEdit(fullName: 'Name'),
          returnsNormally);

      emptyVm.dispose();
    });
  });

  // ── toggleFollow debounce (3 required scenarios) ───────────────────────

  group('toggleFollow', () {
    setUp(() async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile); // isFollowing: false
      await vm.loadProfile('testuser');
    });

    test('optimistic — flips isFollowing and adjusts follower count', () async {
      when(() => mockRepo.followUser(any())).thenAnswer((_) async {});

      final originalFollowers = vm.profile!.stats.followers;

      fakeAsync((fake) {
        vm.toggleFollow();

        // Immediate optimistic update
        expect(vm.profile!.isFollowing, true);
        expect(vm.profile!.stats.followers, originalFollowers + 1);

        fake.elapse(const Duration(milliseconds: 800));
        fake.flushMicrotasks();
      });
    });

    test('scenario 1 — single tap after 800ms fires exactly 1 API call', () {
      when(() => mockRepo.followUser(any())).thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.toggleFollow();

        // Before debounce — no API call
        fake.elapse(const Duration(milliseconds: 799));
        verifyNever(() => mockRepo.followUser(any()));

        // After full window — exactly 1 call
        fake.elapse(const Duration(milliseconds: 2));
        fake.flushMicrotasks();

        verify(() => mockRepo.followUser(any())).called(1);
      });
    });

    test('scenario 2 — second tap while loading is ignored (guard)', () {
      when(() => mockRepo.followUser(any())).thenAnswer((_) async {});

      fakeAsync((fake) {
        vm.toggleFollow(); // first tap — sets _isFollowLoading = true
        vm.toggleFollow(); // ignored — _isFollowLoading guard

        fake.elapse(const Duration(milliseconds: 800));
        fake.flushMicrotasks();

        verify(() => mockRepo.followUser(any())).called(1);
      });
    });

    test('scenario 3 — follow then API failure reverts state', () {
      when(() => mockRepo.followUser(any()))
          .thenThrow(Exception('Follow failed'));

      fakeAsync((fake) {
        final originalFollowing = vm.profile!.isFollowing ?? false; // false
        final originalFollowers = vm.profile!.stats.followers;

        vm.toggleFollow();

        // Optimistic flip
        expect(vm.profile!.isFollowing, !originalFollowing);
        expect(vm.profile!.stats.followers, originalFollowers + 1);

        fake.elapse(const Duration(milliseconds: 800));
        fake.flushMicrotasks();

        // Reverted after failure
        expect(vm.profile!.isFollowing, originalFollowing);
        expect(vm.profile!.stats.followers, originalFollowers);
      });
    });
  });

  // ── loadUserPosts ──────────────────────────────────────────────────────

  group('loadUserPosts', () {
    test('guard — no-op when profile is null', () async {
      // vm has no profile loaded
      await vm.loadUserPosts();

      verifyNever(() => mockRepo.getUserPosts(any()));
    });

    test('happy path — posts loaded', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');

      when(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .thenAnswer((_) async => [tPost]);

      await vm.loadUserPosts();

      expect(vm.posts.length, 1);
      expect(vm.isPostsLoading, false);
    });

    test('guard — second call while loading is ignored', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');

      when(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .thenAnswer((_) async => [tPost]);

      final f1 = vm.loadUserPosts();
      final f2 = vm.loadUserPosts(); // no-op
      await Future.wait([f1, f2]);

      verify(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .called(1);
    });

    test('guard — already loaded, second call is no-op', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');

      when(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .thenAnswer((_) async => [tPost]);

      await vm.loadUserPosts();
      await vm.loadUserPosts(); // already loaded

      verify(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .called(1);
    });

    test('error — silent, empty list kept', () async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');

      when(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .thenThrow(Exception('Network error'));

      await vm.loadUserPosts();

      expect(vm.posts, isEmpty);
      expect(vm.isPostsLoading, false);
    });
  });

  // ── removePost ─────────────────────────────────────────────────────────

  group('removePost', () {
    setUp(() async {
      when(() => mockRepo.getUserProfile('testuser', forceRefresh: false))
          .thenAnswer((_) async => tProfile);
      await vm.loadProfile('testuser');

      when(() => mockRepo.getUserPosts('user-1', forceRefresh: false))
          .thenAnswer((_) async => [tPost]);
      await vm.loadUserPosts();
    });

    test('removes post from list and decrements stats.posts', () {
      final originalPostCount = vm.profile!.stats.posts;

      vm.removePost('post-1');

      expect(vm.posts.any((p) => p.id == 'post-1'), false);
      expect(vm.profile!.stats.posts, originalPostCount - 1);
    });
  });
}
