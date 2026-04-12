import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../ai/song_builder/data/models/song_builder_model.dart';

/// Displays a single song section (verse, hook, bridge, etc.).
///
/// If the section contains the user's own lyrics, a green badge is shown
/// and the lyrics are rendered in a tinted block.
class SongSectionCard extends StatelessWidget {
  final SongSection section;

  const SongSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: section.isDrop
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section name row ──
          Row(
            children: [
              if (section.timestamp != null) ...[
                Text(
                  section.timestamp!,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontFeatures: const [],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                section.name.toUpperCase(),
                style: AppTextStyles.bodySecondary.copyWith(
                  color: section.isDrop
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (section.isDrop) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DROP',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              if (section.isUserLyrics) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Your lyrics',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ── User lyrics block ──
          if (section.isUserLyrics && section.userLyrics != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              child: Text(
                section.userLyrics!,
                style: AppTextStyles.bodyPrimary.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Direction text ──
          Text(
            section.direction,
            style: AppTextStyles.bodyPrimary.copyWith(
              height: 1.5,
              color: section.isDrop
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
