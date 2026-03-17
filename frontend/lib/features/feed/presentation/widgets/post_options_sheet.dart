import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';

class PostOptionsSheet extends StatelessWidget {
  final bool isOwnPost;

  const PostOptionsSheet({super.key, required this.isOwnPost});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 25),

            // Post options
            if (!isOwnPost) ...[
              _OptionTile(
                icon: AppAssets.icon.hide,
                label: 'Hide this post',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: AppAssets.icon.report,
                label: 'Report post',
                iconColor: AppColors.danger,
                textColor: AppColors.danger,
                onTap: () => Navigator.pop(context),
              ),
            ] else ...[
              _OptionTile(
                icon: AppAssets.icon.delete,
                label: 'Delete post',
                iconColor: AppColors.danger,
                textColor: AppColors.danger,
                onTap: () => Navigator.pop(context),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: iconColor ?? AppColors.textWhite,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: textColor ?? AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
