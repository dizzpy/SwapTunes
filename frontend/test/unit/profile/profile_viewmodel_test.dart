import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:swaptune/features/profile/presentation/viewmodels/profile_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late ProfileViewmodel vm;

  setUp(() {
    mockRepo = MockAuthRepository();
    vm = ProfileViewmodel(mockRepo);
  });

  // ── submitProfileSetup ─────────────────────────────────────────────────

  group('submitProfileSetup', () {
    test('happy path — returns true, isLoading resets to false', () async {
      when(
        () => mockRepo.setupProfile(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatarUrl: any(named: 'avatarUrl'),
          genres: any(named: 'genres'),
        ),
      ).thenAnswer((_) async => tUser);

      final result = await vm.submitProfileSetup(
        fullName: 'Test User',
        username: 'testuser',
        genres: ['pop', 'rock'],
      );

      expect(result, true);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('error path — returns false and sets errorMessage', () async {
      when(
        () => mockRepo.setupProfile(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatarUrl: any(named: 'avatarUrl'),
          genres: any(named: 'genres'),
        ),
      ).thenThrow(Exception('Username already taken'));

      final result = await vm.submitProfileSetup(
        fullName: 'Test User',
        username: 'taken',
        genres: ['pop'],
      );

      expect(result, false);
      expect(vm.errorMessage, contains('Username already taken'));
      expect(vm.isLoading, false);
    });

    test('isLoading is true during the call', () async {
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isLoading));

      when(
        () => mockRepo.setupProfile(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatarUrl: any(named: 'avatarUrl'),
          genres: any(named: 'genres'),
        ),
      ).thenAnswer((_) async => tUser);

      await vm.submitProfileSetup(
        fullName: 'Test User',
        username: 'testuser',
        genres: ['pop'],
      );

      // First notification: isLoading = true, last: isLoading = false
      expect(states.first, true);
      expect(states.last, false);
    });
  });
}
