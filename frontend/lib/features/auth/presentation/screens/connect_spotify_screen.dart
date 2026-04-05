import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/spotify_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/connect_spotify_widgets.dart';
import 'welcome_success_screen.dart';

/// Determines the navigation behaviour of [ConnectSpotifyScreen].
enum ConnectSpotifyContext {
  /// During first-time onboarding (shows "Skip for Now", navigates to success).
  onboarding,

  /// From the Discover → Import flow (shows "Nevermind", pops back).
  discover,
}

class ConnectSpotifyScreen extends StatefulWidget {
  final ConnectSpotifyContext flowContext;

  const ConnectSpotifyScreen({
    super.key,
    this.flowContext = ConnectSpotifyContext.onboarding,
  });

  @override
  State<ConnectSpotifyScreen> createState() => _ConnectSpotifyScreenState();
}

class _ConnectSpotifyScreenState extends State<ConnectSpotifyScreen> {
  late final AuthViewmodel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewmodel>();
  }

  @override
  void dispose() {
    _auth.cancelSpotifyConnect();
    super.dispose();
  }

  bool get _isOnboarding =>
      widget.flowContext == ConnectSpotifyContext.onboarding;

  void _navigateToSuccess() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeSuccessScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Opens Spotify auth in browser, waits for callback, exchanges code
  void _onConnectTapped() async {
    // Step 1: Launch Spotify authorization page, wait for the auth code
    final code = await _auth.launchSpotifyConnect();
    if (code == null || !mounted) return;

    // Step 2: Exchange the code with the backend
    final success = await _auth.connectSpotify(
      code,
      SpotifyConstants.connectRedirectUri,
    );

    if (success && mounted) {
      if (_isOnboarding) {
        _navigateToSuccess();
      } else {
        Navigator.of(context).pop(true);
      }
    } else if (mounted) {
      final error = _auth.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _onSkipTapped() {
    if (_isOnboarding) {
      _navigateToSuccess();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.55,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.greenGradient,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Visual header with Spotify logos
                  const DoubleSpotifyHeader(),

                  const SizedBox(height: 36),
                  Text(
                    AppStrings.connectSpotify.title,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.connectSpotify.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),

                  const Spacer(flex: 4),
                  // Permission details
                  const ConnectSpotifyPrivacyInfo(),

                  const SizedBox(height: 20),
                  // Primary connect action button
                  ConnectSpotifyActionBtn(onTap: _onConnectTapped),

                  const SizedBox(height: 24),
                  // Secondary skip / nevermind button
                  TextButton(
                    onPressed: _onSkipTapped,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      _isOnboarding
                          ? AppStrings.connectSpotify.skipBtn
                          : AppStrings.connectSpotify.nevermindBtn,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
