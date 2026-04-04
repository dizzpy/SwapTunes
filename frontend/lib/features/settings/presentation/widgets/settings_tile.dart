import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A single settings row tile.
///
/// [icon] accepts a HugeIcons value (e.g. AppAssets.icon.settings).
/// Use [SettingsToggleTile] for boolean preferences.
class SettingsTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isDanger;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.isDanger = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDanger ? AppColors.danger : AppColors.textWhite;
    final effectiveIconColor = isDanger
        ? AppColors.danger
        : (iconColor ?? AppColors.textSecondary);
    final iconBgColor = isDanger
        ? AppColors.danger.withValues(alpha: 0.12)
        : AppColors.outline.withValues(alpha: 0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      splashColor: AppColors.outline.withValues(alpha: 0.3),
      highlightColor: AppColors.outline.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: effectiveIconColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodySecondary),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                value!,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (showChevron && onTap != null && !isDanger) ...[
              const SizedBox(width: AppSpacing.sm),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A toggle variant of [SettingsTile] with a [Switch] as its trailing widget.
class SettingsToggleTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          inactiveThumbColor: AppColors.textSecondary,
          inactiveTrackColor: AppColors.outline,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }
}
