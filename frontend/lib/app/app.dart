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
      builder: (context, child) {
        return _AuthListener(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}

/// Root widget wrapper that manages auth-based navigation.
///
/// Ensures the listener is placed above the Navigator so that
/// it is never unmounted during pushAndRemoveAll navigation events.
class _AuthListener extends StatefulWidget {
  final Widget child;
  const _AuthListener({required this.child});

  @override
  State<_AuthListener> createState() => _AuthListenerState();
}

class _AuthListenerState extends State<_AuthListener> {
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
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      debugPrint('[_AuthListener] Failed to get initial link: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingLink(uri),
      onError: (Object e) {
        debugPrint('[_AuthListener] Deep link stream error: $e');
      },
    );
  }

  void _handleIncomingLink(Uri uri) {
    if (!mounted) return;
    if (uri.scheme != SupabaseConstants.redirectScheme) return;

    final auth = context.read<AuthViewmodel>();

    if (uri.host == 'spotify-connect') {
      // Spotify connect callback — route to the Completer in AuthViewmodel
      debugPrint('[_AuthListener] Spotify connect callback: $uri');
      auth.handleSpotifyConnectCallback(uri);
    } else {
      // Supabase auth callback (OAuth / magic link)
      debugPrint('[_AuthListener] Auth callback: $uri');
      auth.handleDeepLink(uri);
    }
  }

  // ── Auth-driven navigation ─────────────────────────────

  void _onAuthStatusChanged() {
    if (!mounted) return;

    final auth = context.read<AuthViewmodel>();
    final status = auth.status;

    debugPrint(
      '[_AuthListener] Status changed: $status (last: $_lastHandledStatus)',
    );

    if (status == _lastHandledStatus) return;

    switch (status) {
      case AuthStatus.unauthenticated:
        // Logout or no session — reset flags and go to onboarding.
        _lastHandledStatus = status;
        _isInSetupFlow = false;
        debugPrint('[_AuthListener] Navigating to OnboardingScreen');
        NavigationService.pushAndRemoveAll(const OnboardingScreen());
        break;

      case AuthStatus.authenticated:
        // Authenticated but no profile — enter the setup flow.
        _lastHandledStatus = status;
        _isInSetupFlow = true;
        debugPrint('[_AuthListener] Navigating to ProfileSetupScreen');
        NavigationService.pushAndRemoveAll(const ProfileSetupScreen());
        break;

      case AuthStatus.profileLoaded:
        _lastHandledStatus = status;

        if (_isInSetupFlow) {
          // User just completed profile setup → let the screen flow
          // (ProfileSetup → ConnectSpotify → WelcomeSuccess → Home)
          // navigate itself. Do NOT interfere here.
          debugPrint('[_AuthListener] In setup flow, skipping navigation');
          break;
        }

        // Returning user with an existing profile — go straight to home.
        debugPrint('[_AuthListener] Navigating to MainLayoutScreen');
        NavigationService.pushAndRemoveAll(MainLayoutScreen());
        break;

      case AuthStatus.awaitingOtp:
      case AuthStatus.awaitingOAuth:
      case AuthStatus.initial:
        // Loading states, wait and do nothing.
        _lastHandledStatus = status;
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
    return widget.child;
  }
}
