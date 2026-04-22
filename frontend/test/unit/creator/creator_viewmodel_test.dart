import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swaptune/features/creator/presentation/viewmodels/creator_viewmodel.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockCreatorRepository mockRepo;
  late CreatorViewmodel vm;

  setUp(() {
    mockRepo = MockCreatorRepository();
    vm = CreatorViewmodel(mockRepo);
  });

  group('setupCreator', () {
    test('returns true on success and clears loading', () async {
      when(
        () => mockRepo.setupCreator(
          roleTitle: any(named: 'roleTitle'),
          specializations: any(named: 'specializations'),
          location: any(named: 'location'),
          soundcloudUrl: any(named: 'soundcloudUrl'),
          youtubeUrl: any(named: 'youtubeUrl'),
          spotifyArtistUrl: any(named: 'spotifyArtistUrl'),
          appleMusicUrl: any(named: 'appleMusicUrl'),
          portfolioUrl: any(named: 'portfolioUrl'),
        ),
      ).thenAnswer((_) async => {'ok': true});

      final result = await vm.setupCreator(
        roleTitle: 'Producer',
        specializations: const ['Rock'],
      );

      expect(result, true);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('returns false and sets error on failure', () async {
      when(
        () => mockRepo.setupCreator(
          roleTitle: any(named: 'roleTitle'),
          specializations: any(named: 'specializations'),
          location: any(named: 'location'),
          soundcloudUrl: any(named: 'soundcloudUrl'),
          youtubeUrl: any(named: 'youtubeUrl'),
          spotifyArtistUrl: any(named: 'spotifyArtistUrl'),
          appleMusicUrl: any(named: 'appleMusicUrl'),
          portfolioUrl: any(named: 'portfolioUrl'),
        ),
      ).thenThrow(Exception('creator setup failed'));

      final result = await vm.setupCreator(
        roleTitle: 'Producer',
        specializations: const ['Rock'],
      );

      expect(result, false);
      expect(vm.errorMessage, contains('creator setup failed'));
      expect(vm.isLoading, false);
    });
  });

  group('deactivateCreator', () {
    test('returns true on success', () async {
      when(() => mockRepo.deactivateCreator()).thenAnswer((_) async {});

      final result = await vm.deactivateCreator();

      expect(result, true);
      expect(vm.errorMessage, isNull);
    });

    test('returns false and sets error on failure', () async {
      when(
        () => mockRepo.deactivateCreator(),
      ).thenThrow(Exception('deactivate failed'));

      final result = await vm.deactivateCreator();

      expect(result, false);
      expect(vm.errorMessage, contains('deactivate failed'));
    });
  });
}
