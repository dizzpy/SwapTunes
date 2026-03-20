import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bordered card displaying profile statistics with vertical dividers.
///
/// Shows Followers | Following | Posts | Collabs (creator) or Playlists (listener).
class ProfileStatsCard extends StatelessWidget {
  final int followers;
  final int following;
  final int posts;
  final int collabs;
  final int playlists;
  final bool isCreatorMode;

  const ProfileStatsCard({
    super.key,
    required this.followers,
    required this.following,
    required this.posts,
    required this.collabs,
    required this.playlists,
    required this.isCreatorMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(value: _formatCount(followers), label: 'Followers'),
          const _VerticalDivider(),
          _StatItem(value: _formatCount(following), label: 'Following'),
          const _VerticalDivider(),
          _StatItem(value: posts.toString(), label: 'Posts'),
          const _VerticalDivider(),
          isCreatorMode
              ? _StatItem(value: collabs.toString(), label: 'Collabs')
              : _StatItem(value: playlists.toString(), label: 'Playlists'),
        ],
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyPrimary),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 24, width: 1, color: AppColors.outline);
  }
}
