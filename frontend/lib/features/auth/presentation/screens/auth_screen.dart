import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../../../shared/widgets/app_button.dart';
import '../widgets/auth_background.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AuthBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  Text(
                    AppStrings.auth.welcomeBack,
                    style: AppTextStyles.heading1,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    AppStrings.auth.loginToContinue,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.65),
                    ),
                  ),

                  const SizedBox(height: 40),

                  InputBox(
                    hintText: AppStrings.auth.emailHint,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 16),

                  InputBox(
                    hintText: AppStrings.auth.passwordHint,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: Colors.white70,
                      size: 20,
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppStrings.auth.forgotPassword,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  PrimaryButton(
                    text: AppStrings.auth.loginBtn,
                    onPressed: () {},
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      AppStrings.auth.orContinueWith,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SocialButton(
                    text: AppStrings.auth.continueGoogle,
                    backgroundColor: AppColors.textWhite,
                    foregroundColor: AppColors.background,
                    icon: SvgPicture.asset(
                      'icons/google-logo.svg',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {},
                  ),

                  const SizedBox(height: 12),

                  SocialButton(
                    text: AppStrings.auth.continueSpotify,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    icon: SvgPicture.asset(
                      'icons/spotify-logo.svg',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {},
                  ),

                  const Spacer(),

                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: AppStrings.auth.noAccount,
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.5),
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.auth.signUp,
                            style: AppTextStyles.bodyPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
