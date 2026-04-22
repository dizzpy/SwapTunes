import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swaptune/features/collab/presentation/viewmodels/collab_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockCollabRepository mockRepo;
  late CollabViewmodel vm;

  setUp(() {
    mockRepo = MockCollabRepository();
    vm = CollabViewmodel(mockRepo);
  });

  group('loadCollabs', () {
    test('loads first page and populates collab list', () async {
      final collabs = List.generate(3, (i) => makeCollab(id: 'c-$i'));
      when(
        () => mockRepo.getCollabs(page: 1, role: null),
      ).thenAnswer((_) async => collabs);

      await vm.loadCollabs();

      expect(vm.collabs.length, 3);
      expect(vm.error, isNull);
      expect(vm.isLoading, false);
    });

    test('sets error when repository throws', () async {
      when(
        () => mockRepo.getCollabs(page: 1, role: null),
      ).thenThrow(Exception('load failed'));

      await vm.loadCollabs();

      expect(vm.error, contains('load failed'));
      expect(vm.isLoading, false);
    });
  });

  group('createCollab', () {
    test('creates collab and returns true', () async {
      when(
        () => mockRepo.createCollab(
          title: any(named: 'title'),
          description: any(named: 'description'),
          lookingFor: any(named: 'lookingFor'),
          genreStyle: any(named: 'genreStyle'),
          paymentType: any(named: 'paymentType'),
        ),
      ).thenAnswer((_) async => makeCollab(id: 'new'));
      when(
        () => mockRepo.getCollabs(page: 1, role: null),
      ).thenAnswer((_) async => [makeCollab(id: 'new')]);

      final ok = await vm.createCollab(
        title: 'Need vocalist',
        description: 'for rock track',
        lookingFor: const ['vocalist'],
        genreStyle: const ['rock'],
        paymentType: 'paid',
      );

      expect(ok, true);
      expect(vm.isCreating, false);
      expect(vm.createError, isNull);
    });

    test('returns false and sets createError on failure', () async {
      when(
        () => mockRepo.createCollab(
          title: any(named: 'title'),
          description: any(named: 'description'),
          lookingFor: any(named: 'lookingFor'),
          genreStyle: any(named: 'genreStyle'),
          paymentType: any(named: 'paymentType'),
        ),
      ).thenThrow(Exception('create failed'));

      final ok = await vm.createCollab(
        title: 'Need vocalist',
        description: 'for rock track',
        lookingFor: const ['vocalist'],
        genreStyle: const ['rock'],
        paymentType: 'paid',
      );

      expect(ok, false);
      expect(vm.createError, contains('create failed'));
      expect(vm.isCreating, false);
    });
  });

  group('loadMyCollabs', () {
    test('loads my collabs', () async {
      when(
        () => mockRepo.getMyCollabs(),
      ).thenAnswer((_) async => [makeCollab(id: 'mine-1')]);

      await vm.loadMyCollabs();

      expect(vm.myCollabs.length, 1);
      expect(vm.myCollabsError, isNull);
    });
  });
}
