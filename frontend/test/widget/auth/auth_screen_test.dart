import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:swaptune/features/auth/data/models/user_model.dart';
import 'package:swaptune/features/auth/presentation/screens/auth_screen.dart';
import 'package:swaptune/features/auth/presentation/viewmodels/auth_viewmodel.dart';

// ── Fake AuthViewmodel ─────────────────────────────────────────────────────

class _FakeAuthViewmodel extends ChangeNotifier implements AuthViewmodel {
  final List<String> calls = [];
  final bool _sendMagicLinkResult;

  _FakeAuthViewmodel({bool sendMagicLinkResult = true})
      : _sendMagicLinkResult = sendMagicLinkResult;

  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  AuthStatus get status => AuthStatus.initial;
  @override
  UserModel? get currentUser => null;
  @override
  User? get supabaseUser => null;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoggedIn => false;

  @override
  Future<void> signInWithGoogle() async => calls.add('signInWithGoogle');

  @override
  Future<void> signInWithSpotify() async => calls.add('signInWithSpotify');

  @override
  Future<bool> sendMagicLink(String email) async {
    calls.add('sendMagicLink:$email');
    return _sendMagicLinkResult;
  }

  @override
  Future<bool> handleDeepLink(Uri uri) async => false;
  @override
  Future<void> tryAutoLogin() async {}
  @override
  Future<bool> setupProfile({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async =>
      false;
  @override
  Future<bool> connectSpotify(String code, String redirectUri) async => false;
  @override
  Future<void> refreshCurrentUser() async {}
  @override
  Future<void> logout() async {}
  @override
  void clearError() {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildSubject(_FakeAuthViewmodel fakeVm) {
  return ChangeNotifierProvider<AuthViewmodel>.value(
    value: fakeVm,
    child: const MaterialApp(home: AuthScreen()),
  );
}

void main() {
  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(_buildSubject(_FakeAuthViewmodel()));
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('shows email input field', (tester) async {
    await tester.pumpWidget(_buildSubject(_FakeAuthViewmodel()));
    await tester.pump();
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('tapping Send Magic Link button calls sendMagicLink with email',
      (tester) async {
    final fakeVm = _FakeAuthViewmodel();
    await tester.pumpWidget(_buildSubject(fakeVm));
    await tester.pump();

    // Enter email
    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.pump();

    // Tap the magic link button (finds by text)
    await tester.tap(find.text('Send Magic Link'));
    await tester.pumpAndSettle();

    expect(fakeVm.calls, contains('sendMagicLink:user@test.com'));
  });

  testWidgets('tapping Continue with Google calls signInWithGoogle',
      (tester) async {
    final fakeVm = _FakeAuthViewmodel();
    await tester.pumpWidget(_buildSubject(fakeVm));
    await tester.pump();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(fakeVm.calls, contains('signInWithGoogle'));
  });

  testWidgets('tapping Continue with Spotify calls signInWithSpotify',
      (tester) async {
    final fakeVm = _FakeAuthViewmodel();
    await tester.pumpWidget(_buildSubject(fakeVm));
    await tester.pump();

    await tester.tap(find.text('Continue with Spotify'));
    await tester.pumpAndSettle();

    expect(fakeVm.calls, contains('signInWithSpotify'));
  });
}
