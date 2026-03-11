import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/supabase_constants.dart';
import '../core/services/navigation_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';

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

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _lastHandledStatus;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

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

  void _onAuthStatusChanged() {
    if (!mounted) return;

    final status = context.read<AuthViewmodel>().status;
    if (status == _lastHandledStatus) return;

    switch (status) {
      case AuthStatus.authenticated:
        _lastHandledStatus = status;
        NavigationService.pushAndRemoveAll(const ProfileSetupScreen());
        break;

      case AuthStatus.profileLoaded:
        // Returning user with profile.
        // TODO: Navigate to Home shell when implemented.
        _lastHandledStatus = status;
        NavigationService.pushAndRemoveAll(const ProfileSetupScreen());
        break;

      case AuthStatus.unauthenticated:
        _lastHandledStatus = status;
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    // Safe-remove — addListener may not have fired yet if dispose runs early.
    try {
      context.read<AuthViewmodel>().removeListener(_onAuthStatusChanged);
    } catch (_) {
      // Provider no longer available.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}
