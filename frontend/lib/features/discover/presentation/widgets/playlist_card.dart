import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Unique tag used for the Hero transition to Playlist Detail.
  /// Pass the playlist ID to enable the shared-element cover animation.
  final String? heroTag;

  const PlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square cover image with optional Hero animation
            AspectRatio(aspectRatio: 1, child: _buildCoverImage()),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyPrimary.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(),
            )
          : _buildFallback(),
    );

    if (heroTag == null) return imageWidget;

    return Hero(tag: heroTag!, child: imageWidget);
  }

  Widget _buildFallback() {
    return Container(
      width: double.infinity,
      color: AppColors.skeletonHighlight,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }
}
