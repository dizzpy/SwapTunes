import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/full_profile_model.dart';

/// Creator-specific info: role tag, location, and first link
/// with a "See More" action that opens a links bottom sheet.
///
/// Only rendered when [profile.isCreator] is true.
class CreatorInfoSection extends StatelessWidget {
  final CreatorProfile creator;

  const CreatorInfoSection({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final firstLink = _firstLink;

    return Column(
      children: [
        Row(
          children: [
            if (creator.roleTitle != null) ...[
              const HugeIcon(
                icon: HugeIcons.strokeRoundedMusicNote03,
                color: AppColors.primary,
                size: 18.0,
              ),
              const SizedBox(width: 8),
              Text(
                creator.roleTitle!,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            if (creator.roleTitle != null && creator.location != null)
              const SizedBox(width: 16),
            if (creator.location != null) ...[
              const HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                color: AppColors.primary,
                size: 18.0,
              ),
              const SizedBox(width: 8),
              Text(
                creator.location!,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
        if (firstLink != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedLink01,
                color: AppColors.primary,
                size: 18.0,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  firstLink,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _showLinksBottomSheet(context),
                child: Text('See More', style: AppTextStyles.bodySecondary70),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String? get _firstLink =>
      creator.soundcloudUrl ??
      creator.spotifyArtistUrl ??
      creator.youtubeUrl ??
      creator.appleMusicUrl ??
      creator.portfolioUrl;

  void _showLinksBottomSheet(BuildContext context) {
    final links = <_LinkEntry>[
      if (creator.soundcloudUrl != null)
        _LinkEntry('SoundCloud', creator.soundcloudUrl!),
      if (creator.spotifyArtistUrl != null)
        _LinkEntry('Spotify', creator.spotifyArtistUrl!),
      if (creator.youtubeUrl != null)
        _LinkEntry('YouTube', creator.youtubeUrl!),
      if (creator.appleMusicUrl != null)
        _LinkEntry('Apple Music', creator.appleMusicUrl!),
      if (creator.portfolioUrl != null)
        _LinkEntry('Portfolio', creator.portfolioUrl!),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardFront,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
              ...links.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildLinkItem(e.title, e.url),
                ),
              ),
              const SizedBox(height: 8),
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

class _LinkEntry {
  final String title;
  final String url;
  const _LinkEntry(this.title, this.url);
}
