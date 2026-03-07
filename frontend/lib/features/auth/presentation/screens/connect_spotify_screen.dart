import 'package:flutter/material.dart';
import 'package:swaptune/core/constants/app_strings.dart';
import 'package:swaptune/core/theme/app_colors.dart';
import 'package:swaptune/core/theme/app_text_styles.dart';
import '../widgets/connect_spotify_widgets.dart';
import 'welcome_success_screen.dart';

class ConnectSpotifyScreen extends StatefulWidget {
  const ConnectSpotifyScreen({super.key});

  @override
  State<ConnectSpotifyScreen> createState() => _ConnectSpotifyScreenState();
}

class _ConnectSpotifyScreenState extends State<ConnectSpotifyScreen> {
  // Connects the user's Spotify account and proceeds
  void _onConnectTapped() {
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

  // Skips the Spotify connection for now
  void _onSkipTapped() {
    _onConnectTapped();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // Privacy disclaimer text
                const ConnectSpotifyPrivacyInfo(),

                const SizedBox(height: 20),
                // Primary connect action button
                ConnectSpotifyActionBtn(onTap: _onConnectTapped),

                const SizedBox(height: 24),
                // Secondary skip action button
                TextButton(
                  onPressed: _onSkipTapped,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Text(
                    AppStrings.connectSpotify.skipBtn,
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
    );
  }
}
