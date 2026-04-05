import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TrendingTagChip extends StatelessWidget {
  final String label;

  const TrendingTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(20),
        // No prominent outline border needed based on the design, or keep it subtle
        // border: Border.all(color: AppColors.outline),
      ),
      child: Text(label, style: AppTextStyles.bodySecondaryWhite),
    );
  }
}
