import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swaptune/features/auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late StreamController<AuthState> authStateController;
  late AuthViewmodel vm;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStateController = StreamController<AuthState>.broadcast();

    when(
      () => mockRepo.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);
    when(() => mockRepo.isLoggedIn).thenReturn(false);
    when(() => mockRepo.hasSupabaseSession).thenReturn(false);

    vm = AuthViewmodel(mockRepo);
  });

  tearDown(() {
    vm.dispose();
    authStateController.close();
  });

  group('OTP flow', () {
    test('sendOtp sets awaitingOtp and pendingEmail on success', () async {
      when(() => mockRepo.sendOtp('user@test.com')).thenAnswer((_) async {});

      final ok = await vm.sendOtp('user@test.com');

      expect(ok, true);
      expect(vm.status, AuthStatus.awaitingOtp);
      expect(vm.pendingEmail, 'user@test.com');
      expect(vm.otpError, isNull);
    });

    test('verifyOtp fails when pending email is missing', () async {
      final ok = await vm.verifyOtp('123456');

      expect(ok, false);
      expect(vm.otpError, 'No pending email found');
    });

    test('verifyOtp sets invalid code error for AuthException', () async {
      when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(AuthException('Invalid OTP code'));

      await vm.sendOtp('user@test.com');
      final ok = await vm.verifyOtp('000000');

      expect(ok, false);
      expect(vm.otpError, contains('Invalid code'));
    });

    test('verifyOtp sets expired code error for token expiry', () async {
      when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(AuthException('Token has expired'));

      await vm.sendOtp('user@test.com');
      final ok = await vm.verifyOtp('111111');

      expect(ok, false);
      expect(vm.otpError, contains('Code expired'));
      expect(vm.canResendOtp, true);
    });
  });
}
