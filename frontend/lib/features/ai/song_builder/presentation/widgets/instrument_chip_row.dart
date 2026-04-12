import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// A horizontally scrollable single-line row of instrument chips.
class InstrumentChipRow extends StatelessWidget {
  final List<String> instruments;

  const InstrumentChipRow({super.key, required this.instruments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < instruments.length; i++) ...[
            _InstrumentChip(label: instruments[i]),
            if (i < instruments.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  final String label;

  const _InstrumentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
      ),
    );
  }
}
