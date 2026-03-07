import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../profile/presentation/screens/profile_setup_screen.dart';

class AuthBottomSheet extends StatelessWidget {
  const AuthBottomSheet({super.key});

  // Closes the current bottom sheet and pushes to the profile setup screen
  void _goToProfileSetup(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileSetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
                AppAssets.icons.googleLogo,
                width: 24,
                height: 24,
              ),
              onPressed: () => _goToProfileSetup(context),
            ),
            const SizedBox(height: 12),

            // Spotify authentication button
            SocialButton(
              text: AppStrings.auth.continueSpotify,
              backgroundColor: AppColors.greenDarkBg,
              foregroundColor: AppColors.textWhite,
              icon: SvgPicture.asset(
                AppAssets.icons.spotifyLogo,
                width: 24,
                height: 24,
              ),
              onPressed: () => _goToProfileSetup(context),
            ),
            const SizedBox(height: 12),

            // Email / Magic link fallback button
            OutlinedAppButton(
              text: AppStrings.onboarding.continueMagicLink,
              onPressed: () => _goToProfileSetup(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
