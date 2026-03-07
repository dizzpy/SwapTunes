import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Central title and subtitle for the Welcome Success Screen
class WelcomeTitleBox extends StatelessWidget {
  const WelcomeTitleBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.welcomeSuccess.title,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.welcomeSuccess.subtitle,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textWhite,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The main action button for the Welcome Success Screen
class WelcomeContinueBtn extends StatelessWidget {
  final VoidCallback onTap;

  const WelcomeContinueBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              AppStrings.welcomeSuccess.continueBtn,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top-right replay button with a cooldown timer
class ConfettiReplayBtn extends StatelessWidget {
  final int cooldownSeconds;
  final bool isConfettiPlaying;
  final VoidCallback onReplay;

  const ConfettiReplayBtn({
    super.key,
    required this.cooldownSeconds,
    required this.isConfettiPlaying,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 10.0),
          child: IconButton(
            icon: cooldownSeconds > 0
                ? Text(
                    '$cooldownSeconds',
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  )
                : const Icon(
                    Icons.celebration_rounded,
                    color: AppColors.textSecondary,
                  ),
            tooltip: cooldownSeconds > 0
                ? 'Wait $cooldownSeconds s'
                : 'Replay confetti',
            onPressed: isConfettiPlaying ? null : onReplay,
          ),
        ),
      ),
    );
  }
}
