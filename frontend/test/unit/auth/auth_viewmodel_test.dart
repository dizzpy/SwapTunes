import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:swaptune/features/auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late StreamController<AuthState> authStateController;
  late AuthViewmodel vm;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStateController = StreamController<AuthState>.broadcast();

    // AuthViewmodel subscribes to this stream in its constructor
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => authStateController.stream);
    when(() => mockRepo.isLoggedIn).thenReturn(false);
    when(() => mockRepo.hasSupabaseSession).thenReturn(false);

    vm = AuthViewmodel(mockRepo);
  });

  tearDown(() {
    vm.dispose();
    authStateController.close();
  });

  // ── signInWithGoogle ───────────────────────────────────────────────────

  group('signInWithGoogle', () {
    test('happy path — sets awaitingOAuth and clears loading', () async {
      when(() => mockRepo.signInWithGoogle()).thenAnswer((_) async {});

      await vm.signInWithGoogle();

      expect(vm.status, AuthStatus.awaitingOAuth);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('error path — sets error message and clears loading', () async {
      when(() => mockRepo.signInWithGoogle())
          .thenThrow(Exception('OAuth failed'));

      await vm.signInWithGoogle();

      expect(vm.errorMessage, contains('OAuth failed'));
      expect(vm.isLoading, false);
      expect(vm.status, isNot(AuthStatus.awaitingOAuth));
    });
  });

  // ── signInWithSpotify ──────────────────────────────────────────────────

  group('signInWithSpotify', () {
    test('happy path — sets awaitingOAuth and clears loading', () async {
      when(() => mockRepo.signInWithSpotify()).thenAnswer((_) async {});

      await vm.signInWithSpotify();

      expect(vm.status, AuthStatus.awaitingOAuth);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('error path — sets error message', () async {
      when(() => mockRepo.signInWithSpotify())
          .thenThrow(Exception('Spotify OAuth failed'));

      await vm.signInWithSpotify();

      expect(vm.errorMessage, contains('Spotify OAuth failed'));
      expect(vm.isLoading, false);
    });
  });

  // ── sendMagicLink ──────────────────────────────────────────────────────

  group('sendMagicLink', () {
    test('happy path — returns true and sets awaitingMagicLink', () async {
      when(() => mockRepo.signInWithMagicLink(any()))
          .thenAnswer((_) async {});

      final result = await vm.sendMagicLink('test@example.com');

      expect(result, true);
      expect(vm.status, AuthStatus.awaitingMagicLink);
      expect(vm.isLoading, false);
    });

    test('error path — returns false and sets error message', () async {
      when(() => mockRepo.signInWithMagicLink(any()))
          .thenThrow(Exception('Invalid email'));

      final result = await vm.sendMagicLink('bad-email');

      expect(result, false);
      expect(vm.errorMessage, contains('Invalid email'));
      expect(vm.status, isNot(AuthStatus.awaitingMagicLink));
    });
  });

  // ── handleDeepLink ─────────────────────────────────────────────────────

  group('handleDeepLink', () {
    final uri = Uri.parse('swaptunes://auth/callback?code=abc');

    test('success — loads profile and returns true', () async {
      when(() => mockRepo.handleAuthCallback(uri))
          .thenAnswer((_) async => true);
      when(() => mockRepo.syncTokenToStorage()).thenAnswer((_) async {});
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      final result = await vm.handleDeepLink(uri);

      expect(result, true);
      expect(vm.currentUser, tUser);
      expect(vm.status, AuthStatus.profileLoaded);
    });

    test('failure — returns false and sets error', () async {
      when(() => mockRepo.handleAuthCallback(uri))
          .thenThrow(Exception('Callback failed'));

      final result = await vm.handleDeepLink(uri);

      expect(result, false);
      expect(vm.errorMessage, contains('Callback failed'));
    });

    test('callback returns false — returns false, status stays initial',
        () async {
      when(() => mockRepo.handleAuthCallback(uri))
          .thenAnswer((_) async => false);

      final result = await vm.handleDeepLink(uri);

      expect(result, false);
    });
  });

  // ── tryAutoLogin ───────────────────────────────────────────────────────

  group('tryAutoLogin', () {
    test('not logged in — exits early, no API call', () async {
      when(() => mockRepo.isLoggedIn).thenReturn(false);

      await vm.tryAutoLogin();

      verifyNever(() => mockRepo.getCurrentUser());
      expect(vm.status, AuthStatus.initial);
    });

    test('logged in — loads user and sets profileLoaded', () async {
      when(() => mockRepo.isLoggedIn).thenReturn(true);
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      await vm.tryAutoLogin();

      expect(vm.currentUser, tUser);
      expect(vm.status, AuthStatus.profileLoaded);
    });

    test('expired token — calls logout and sets unauthenticated', () async {
      when(() => mockRepo.isLoggedIn).thenReturn(true);
      when(() => mockRepo.getCurrentUser())
          .thenThrow(Exception('Token expired'));
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      await vm.tryAutoLogin();

      verify(() => mockRepo.logout()).called(1);
      expect(vm.currentUser, isNull);
      expect(vm.status, AuthStatus.unauthenticated);
    });
  });

  // ── setupProfile ───────────────────────────────────────────────────────

  group('setupProfile', () {
    test('happy path — stores user and returns true', () async {
      when(
        () => mockRepo.setupProfile(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatarUrl: any(named: 'avatarUrl'),
          genres: any(named: 'genres'),
        ),
      ).thenAnswer((_) async => tUser);

      final result = await vm.setupProfile(
        fullName: 'Test User',
        username: 'testuser',
        genres: ['pop'],
      );

      expect(result, true);
      expect(vm.currentUser, tUser);
      expect(vm.status, AuthStatus.profileLoaded);
    });

    test('error path — returns false and sets error', () async {
      when(
        () => mockRepo.setupProfile(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatarUrl: any(named: 'avatarUrl'),
          genres: any(named: 'genres'),
        ),
      ).thenThrow(Exception('Username taken'));

      final result = await vm.setupProfile(
        fullName: 'Test User',
        username: 'taken',
        genres: ['pop'],
      );

      expect(result, false);
      expect(vm.errorMessage, contains('Username taken'));
    });
  });

  // ── connectSpotify ─────────────────────────────────────────────────────

  group('connectSpotify', () {
    test('happy path — refreshes current user and returns true', () async {
      when(() => mockRepo.connectSpotify(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      final result = await vm.connectSpotify('code123', 'https://redirect.uri');

      expect(result, true);
      expect(vm.currentUser, tUser);
    });

    test('error path — returns false and sets error', () async {
      when(() => mockRepo.connectSpotify(any(), any()))
          .thenThrow(Exception('Connection failed'));

      final result = await vm.connectSpotify('bad-code', 'https://redirect.uri');

      expect(result, false);
      expect(vm.errorMessage, contains('Connection failed'));
    });
  });

  // ── refreshCurrentUser ─────────────────────────────────────────────────

  group('refreshCurrentUser', () {
    test('happy path — loads user', () async {
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      await vm.refreshCurrentUser();

      expect(vm.currentUser, tUser);
      expect(vm.status, AuthStatus.profileLoaded);
    });

    test('error path — clears user and sets error', () async {
      // Pre-load a user
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);
      await vm.refreshCurrentUser();
      expect(vm.currentUser, tUser);

      // Now fail
      when(() => mockRepo.getCurrentUser())
          .thenThrow(Exception('Network error'));
      await vm.refreshCurrentUser();

      expect(vm.currentUser, isNull);
      expect(vm.errorMessage, isNotNull);
    });
  });

  // ── logout ─────────────────────────────────────────────────────────────

  group('logout', () {
    test('clears user and sets unauthenticated', () async {
      // Pre-load a user
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);
      await vm.refreshCurrentUser();
      expect(vm.currentUser, tUser);

      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await vm.logout();

      expect(vm.currentUser, isNull);
      expect(vm.status, AuthStatus.unauthenticated);
    });
  });

  // ── clearError ─────────────────────────────────────────────────────────

  group('clearError', () {
    test('clears the error message', () async {
      when(() => mockRepo.signInWithGoogle())
          .thenThrow(Exception('Some error'));
      await vm.signInWithGoogle();
      expect(vm.errorMessage, isNotNull);

      vm.clearError();
      expect(vm.errorMessage, isNull);
    });
  });

  // ── auth stream events ─────────────────────────────────────────────────

  group('auth stream — signedIn event', () {
    test('syncs token and loads profile', () async {
      when(() => mockRepo.syncTokenToStorage()).thenAnswer((_) async {});
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      authStateController
          .add(const AuthState(AuthChangeEvent.signedIn, null));
      await Future.delayed(Duration.zero); // let stream listeners run

      verify(() => mockRepo.syncTokenToStorage()).called(1);
      expect(vm.currentUser, tUser);
      expect(vm.status, AuthStatus.profileLoaded);
    });
  });

  group('auth stream — signedOut event', () {
    test('clears user and sets unauthenticated', () async {
      // Pre-load user
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);
      when(() => mockRepo.syncTokenToStorage()).thenAnswer((_) async {});
      authStateController
          .add(const AuthState(AuthChangeEvent.signedIn, null));
      await Future.delayed(Duration.zero);

      authStateController
          .add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future.delayed(Duration.zero);

      expect(vm.currentUser, isNull);
      expect(vm.status, AuthStatus.unauthenticated);
    });
  });

  group('auth stream — initialSession with session', () {
    test('syncs token and loads profile', () async {
      when(() => mockRepo.hasSupabaseSession).thenReturn(true);
      when(() => mockRepo.syncTokenToStorage()).thenAnswer((_) async {});
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

      authStateController
          .add(const AuthState(AuthChangeEvent.initialSession, null));
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.syncTokenToStorage()).called(1);
      expect(vm.currentUser, tUser);
    });
  });

  group('auth stream — initialSession without session', () {
    test('sets unauthenticated immediately', () async {
      when(() => mockRepo.hasSupabaseSession).thenReturn(false);

      authStateController
          .add(const AuthState(AuthChangeEvent.initialSession, null));
      await Future.delayed(Duration.zero);

      expect(vm.status, AuthStatus.unauthenticated);
      verifyNever(() => mockRepo.getCurrentUser());
    });
  });
}
