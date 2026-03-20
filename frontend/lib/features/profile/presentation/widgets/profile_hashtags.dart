import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Horizontal row of genre hashtag chips.
///
/// Creator mode: left-aligned, muted style.
/// Listener mode: center-aligned, primary color.
class ProfileHashtags extends StatelessWidget {
  final List<String> hashtags;
  final bool isCreatorMode;

  const ProfileHashtags({
    super.key,
    required this.hashtags,
    required this.isCreatorMode,
  });

  @override
  Widget build(BuildContext context) {
    final style = isCreatorMode
        ? AppTextStyles.bodySecondary70
        : AppTextStyles.bodySecondary.copyWith(color: AppColors.primary);

    return Row(
      mainAxisAlignment:
          isCreatorMode ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: hashtags.map((tag) {
        return Padding(
          padding: EdgeInsets.only(
            right: isCreatorMode ? 12.0 : 6.0,
            left: isCreatorMode ? 0 : 6.0,
          ),
          child: Text(tag, style: style),
        );
      }).toList(),
    );
  }
}
