import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Creator-specific info: role tag, location tag, and external link
/// with a "See More" action that opens a links bottom sheet.
///
/// Only rendered when the profile is in creator mode.
class CreatorInfoSection extends StatelessWidget {
  const CreatorInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedMusicNote03,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'Producer/Engineer',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'Producer/Engineer',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLink01,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'soundcloud.com/dizzpysanchez',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showLinksBottomSheet(context),
              child: Text('See More', style: AppTextStyles.bodySecondary70),
            ),
          ],
        ),
      ],
    );
  }

  void _showLinksBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardFront,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
              const SizedBox(height: 32),
              _buildLinkItem('SoundCloud', 'soundcloud.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem('Spotify', 'spotify.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem('YouTube', 'youtube.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem(
                  'Apple Music', 'applemusic.com/dizzpysanchez'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return Row(
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedLink01,
          color: AppColors.textWhite,
          size: 24.0,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyPrimary),
            const SizedBox(height: 4),
            Text(url, style: AppTextStyles.bodySecondary70),
          ],
        ),
      ],
    );
  }
}
