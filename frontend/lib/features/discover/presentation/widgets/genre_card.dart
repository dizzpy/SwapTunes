import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A visually styled genre card used in the Browse All Genres grid.
///
/// Each card has a unique [accentColor] to distinguish genres visually.
class GenreCard extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const GenreCard({
    super.key,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Accent color bar at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 6, color: accentColor),
            ),
            // Accent glow behind the label area
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Genre label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                label,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
