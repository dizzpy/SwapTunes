import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/creator_profile_form.dart';
import 'creator_setup_success.dart';

class BecomeACreator extends StatelessWidget {
  /// Pass existing creator profile for re-activation pre-fill.
  final CreatorProfileForm? existingProfile;

  const BecomeACreator({super.key, this.existingProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.creatorGradientTop, AppColors.background],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                Center(
                  child: Text(
                    AppStrings.creator.becomeCreatorTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppStrings.creator.becomeCreatorSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                const SizedBox(height: 48),

                _FeatureItem(
                  title: AppStrings.creator.featureCollabTitle,
                  subtitle: AppStrings.creator.featureCollabSubtitle,
                ),
                _FeatureItem(
                  title: AppStrings.creator.featureBadgeTitle,
                  subtitle: AppStrings.creator.featureBadgeSubtitle,
                ),
                _FeatureItem(
                  title: AppStrings.creator.featureEngageTitle,
                  subtitle: AppStrings.creator.featureEngageSubtitle,
                ),
                _FeatureItem(
                  title: AppStrings.creator.featurePortfolioTitle,
                  subtitle: AppStrings.creator.featurePortfolioSubtitle,
                ),

                const Spacer(),

                GreenButton(
                  text: AppStrings.creator.continueToSetupBtn,
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          CreatorSetup(existingProfile: existingProfile),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppStrings.creator.nevermindBtn,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FeatureItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: HugeIcon(
              icon: AppAssets.icon.check,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyPrimary),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
