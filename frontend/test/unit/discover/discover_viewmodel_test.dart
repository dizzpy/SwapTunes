import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swaptune/features/discover/presentation/viewmodels/discover_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockDiscoverRepository discoverRepo;
  late MockProfileRepository profileRepo;

  setUp(() {
    discoverRepo = MockDiscoverRepository();
    profileRepo = MockProfileRepository();
  });

  test('loads genres/playlists/suggested users on init', () async {
    when(() => discoverRepo.getGenres()).thenAnswer((_) async => ['rock']);
    when(
      () => discoverRepo.getDiscoverPlaylists(page: 1, limit: 10),
    ).thenAnswer((_) async => [makePlaylist()]);
    when(
      () => discoverRepo.getSuggestedUsers(limit: 20),
    ).thenAnswer((_) async => [makeSuggestedUser()]);

    final vm = DiscoverViewModel(discoverRepo, profileRepo);
    await Future<void>.delayed(Duration.zero);

    expect(vm.isLoading, false);
    expect(vm.error, isNull);
    expect(vm.genres, ['rock']);
    expect(vm.playlists.length, 1);
    expect(vm.suggestedUsers.length, 1);
  });

  test('toggleFollow follows then unfollows', () async {
    when(() => discoverRepo.getGenres()).thenAnswer((_) async => []);
    when(
      () => discoverRepo.getDiscoverPlaylists(page: 1, limit: 10),
    ).thenAnswer((_) async => []);
    when(
      () => discoverRepo.getSuggestedUsers(limit: 20),
    ).thenAnswer((_) async => []);

    when(() => profileRepo.followUser('u-1')).thenAnswer((_) async {});
    when(() => profileRepo.unfollowUser('u-1')).thenAnswer((_) async {});

    final vm = DiscoverViewModel(discoverRepo, profileRepo);
    await Future<void>.delayed(Duration.zero);

    await vm.toggleFollow('u-1');
    expect(vm.isFollowing('u-1'), true);

    await vm.toggleFollow('u-1');
    expect(vm.isFollowing('u-1'), false);
  });

  test('retry recovers from initial load failure', () async {
    when(() => discoverRepo.getGenres()).thenThrow(Exception('network down'));
    when(
      () => discoverRepo.getDiscoverPlaylists(page: 1, limit: 10),
    ).thenAnswer((_) async => []);
    when(
      () => discoverRepo.getSuggestedUsers(limit: 20),
    ).thenAnswer((_) async => []);

    final vm = DiscoverViewModel(discoverRepo, profileRepo);
    await Future<void>.delayed(Duration.zero);

    expect(vm.error, isNotNull);

    when(() => discoverRepo.getGenres()).thenAnswer((_) async => ['pop']);

    await vm.retry();

    expect(vm.error, isNull);
    expect(vm.genres, ['pop']);
  });
}
