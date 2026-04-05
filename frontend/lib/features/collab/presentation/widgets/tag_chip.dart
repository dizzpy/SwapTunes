import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showBorder;

  const TagChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : showBorder
              ? Colors.transparent
              : AppColors.cardFront,
          borderRadius: BorderRadius.circular(20),
          border: showBorder
              ? Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySecondary.copyWith(
            color: isSelected
                ? AppColors.textWhite
                : showBorder
                ? AppColors.textSecondary
                : AppColors.textWhite,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
