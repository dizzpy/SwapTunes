import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class GenreSelectionWrap extends StatelessWidget {
  final List<String> availableGenres;
  final Set<String> selectedGenres;
  final ValueChanged<String> onGenreToggled;

  const GenreSelectionWrap({
    super.key,
    required this.availableGenres,
    required this.selectedGenres,
    required this.onGenreToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: availableGenres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        return GestureDetector(
          onTap: () => onGenreToggled(genre),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.greenDarkBg : AppColors.cardFront,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              genre,
              style: AppTextStyles.bodySecondary.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textWhite,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
