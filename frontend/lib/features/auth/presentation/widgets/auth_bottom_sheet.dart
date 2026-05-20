import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'email_input.dart';

/// Bottom sheet shown on the onboarding screen with social login options.
///
/// Connects to Supabase Auth via [AuthViewmodel] for Google OAuth,
/// Spotify OAuth, and OTP-based email sign-in.
class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  bool _isProcessing = false;

  /// Handles Google sign-in via Supabase OAuth.
  Future<void> _handleGoogleAuth() async {
    if (_isProcessing) return;
    AppHaptics.buttonTap();
    setState(() => _isProcessing = true);

    final auth = context.read<AuthViewmodel>();
    await auth.signInWithGoogle();

    if (mounted) {
      // Close the bottom sheet — the OAuth browser opens externally.
      // Auth state listener in AuthViewmodel handles the callback.
      Navigator.of(context).pop();
    }
  }

  /// Handles Spotify sign-in via Supabase OAuth.
  Future<void> _handleSpotifyAuth() async {
    if (_isProcessing) return;
    AppHaptics.buttonTap();
    setState(() => _isProcessing = true);

    final auth = context.read<AuthViewmodel>();
    await auth.signInWithSpotify();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Opens the email input UI for OTP authentication.
  void _handleEmailAuth() {
    AppHaptics.buttonTap();
    final navigator = Navigator.of(context);

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;

      showModalBottomSheet(
        context: navigator.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EmailInput(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              AppStrings.onboarding.createAccount,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 25),

            // Google authentication button
            SocialButton(
              text: AppStrings.auth.continueGoogle,
              backgroundColor: AppColors.cardFront,
              foregroundColor: AppColors.textWhite,
              icon: SvgPicture.asset(
                AppAssets.img.googleLogo,
                width: 24,
                height: 24,
              ),
              onPressed: _isProcessing ? () {} : _handleGoogleAuth,
            ),
            const SizedBox(height: 12),

            // Spotify authentication button
            SocialButton(
              text: AppStrings.auth.continueSpotify,
              backgroundColor: AppColors.greenDarkBg,
              foregroundColor: AppColors.textWhite,
              icon: SvgPicture.asset(
                AppAssets.img.spotifyLogo,
                width: 24,
                height: 24,
              ),
              onPressed: _isProcessing ? () {} : _handleSpotifyAuth,
            ),
            const SizedBox(height: 12),

            // Email / OTP authentication button
            OutlinedAppButton(
              text: AppStrings.onboarding.continueWithEmail,
              onPressed: _isProcessing ? () {} : _handleEmailAuth,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
