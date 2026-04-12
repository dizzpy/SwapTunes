import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../ai/song_builder/data/models/song_builder_model.dart';

/// Timeline-style drop map for EDM/Electronic instrumental tracks.
///
/// Each section is shown as a row: timestamp | name | description.
/// DROP sections are highlighted with a green left accent.
class DropMapCard extends StatelessWidget {
  final List<SongSection> sections;

  const DropMapCard({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: sections.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isLast = i == sections.length - 1;

          return _DropRow(section: s, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _DropRow extends StatelessWidget {
  final SongSection section;
  final bool isLast;

  const _DropRow({required this.section, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: section.isDrop ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.outline.withValues(alpha: 0.12)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 40,
            child: Text(
              section.timestamp ?? '',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Section name
          SizedBox(
            width: 80,
            child: Text(
              section.name,
              style: AppTextStyles.bodySecondary.copyWith(
                color: section.isDrop
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: section.isDrop ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Direction
          Expanded(
            child: Text(
              section.direction,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
