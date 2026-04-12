import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../data/models/song_builder_model.dart';

/// Modal bottom sheet displaying the full song structure section by section.
///
/// Opens from the "View Song Structure" button on [SongBuilderResultScreen].
/// Draggable from 70 % to full screen height.
class SongStructureSheet extends StatelessWidget {
  final SongBuilderResult result;

  const SongStructureSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.songBuilder.structureSheetTitle,
                  style: AppTextStyles.heading3,
                ),
              ),
              const SizedBox(height: 16),

              // ── Section list ──
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: result.sections.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.outline.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, i) =>
                      _SectionRow(section: result.sections[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION ROW
// ─────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final SongSection section;

  const _SectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: section.isDrop
          ? BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            )
          : null,
      child: Padding(
        // Indent content when the green left border is showing
        padding: EdgeInsets.only(left: section.isDrop ? 12 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name row ──
            Row(
              children: [
                Text(
                  section.name.toUpperCase(),
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: section.isDrop
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                if (section.timestamp != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    section.timestamp!,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (section.isUserLyrics) ...[
                  const SizedBox(width: 8),
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
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Direction ──
            Text(
              section.direction,
              style: AppTextStyles.bodyPrimary.copyWith(
                height: 1.5,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
