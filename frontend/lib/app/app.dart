import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/supabase_constants.dart';
import '../core/services/navigation_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/feed/presentation/screens/main_layout_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

class SwapTuneApp extends StatelessWidget {
  const SwapTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwapTune',
      theme: AppTheme.darkTheme,
      navigatorKey: NavigationService.navigatorKey,
      home: const _AuthGate(),
    );
  }
}

/// Root widget that manages auth-based navigation.
///
/// Shows a splash screen during initial auth check, then navigates to the
/// correct screen based on auth status:
///   - unauthenticated → OnboardingScreen
///   - authenticated (no profile) → ProfileSetupScreen
///   - profileLoaded (returning user) → MainLayoutScreen
///
/// During the first-time setup flow (ProfileSetup → ConnectSpotify →
/// WelcomeSuccess → Home), the gate deliberately steps back and lets
/// the screens navigate manually to avoid hijacking the flow.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _lastHandledStatus;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  /// Tracks whether the user is currently in the first-time
  /// profile setup flow (ProfileSetup → ConnectSpotify → WelcomeSuccess).
  /// When true, `profileLoaded` events are ignored so the AuthGate
  /// doesn't hijack the manual screen-to-screen navigation.
  bool _isInSetupFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewmodel>().addListener(_onAuthStatusChanged);
      _initDeepLinks();
    });
  }

  // ── Deep link handling ─────────────────────────────────

  Future<void> _initDeepLinks() async {
    // Cold-start: app was opened by tapping the magic link / OAuth redirect
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && _isAuthCallback(initialUri)) {
        debugPrint('[AuthGate] Cold-start deep link: $initialUri');
        if (mounted) {
          await context.read<AuthViewmodel>().handleDeepLink(initialUri);
        }
      }
    } catch (e) {
      debugPrint('[AuthGate] Failed to get initial link: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) async {
        if (_isAuthCallback(uri) && mounted) {
          debugPrint('[AuthGate] Warm deep link: $uri');
          await context.read<AuthViewmodel>().handleDeepLink(uri);
        }
      },
      onError: (Object e) {
        debugPrint('[AuthGate] Deep link stream error: $e');
      },
    );
  }

  bool _isAuthCallback(Uri uri) =>
      uri.scheme == SupabaseConstants.redirectScheme;

  // ── Auth-driven navigation ─────────────────────────────

  void _onAuthStatusChanged() {
    if (!mounted) return;

    final status = context.read<AuthViewmodel>().status;
    if (status == _lastHandledStatus) return;

    switch (status) {
      case AuthStatus.unauthenticated:
        // Logout or no session — reset flags and go to onboarding.
        _lastHandledStatus = status;
        _isInSetupFlow = false;
        NavigationService.pushAndRemoveAll(const OnboardingScreen());
        break;

      case AuthStatus.authenticated:
        // Authenticated but no profile — enter the setup flow.
        _lastHandledStatus = status;
        _isInSetupFlow = true;
        NavigationService.pushAndRemoveAll(const ProfileSetupScreen());
        break;

      case AuthStatus.profileLoaded:
        _lastHandledStatus = status;

        if (_isInSetupFlow) {
          // User just completed profile setup → let the screen flow
          // (ProfileSetup → ConnectSpotify → WelcomeSuccess → Home)
          // navigate itself. Do NOT interfere here.
          break;
        }

        // Returning user with an existing profile — go straight to home.
        NavigationService.pushAndRemoveAll(const MainLayoutScreen());
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    try {
      context.read<AuthViewmodel>().removeListener(_onAuthStatusChanged);
    } catch (_) {
      // Provider no longer available.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while the auth state is still being determined.
    return const SplashScreen();
  }
}
