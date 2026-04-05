import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Horizontal tab bar for profile content sections.
///
/// Creator mode: Posts | Collabs | Songs
/// Listener mode: Posts | Playlists
class ProfileContentTabs extends StatelessWidget {
  final int selectedIndex;
  final bool isCreatorMode;
  final ValueChanged<int> onTabChanged;

  const ProfileContentTabs({
    super.key,
    required this.selectedIndex,
    required this.isCreatorMode,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _TabItem(
          label: 'Posts',
          iconData: AppAssets.icon.image,
          isActive: selectedIndex == 0,
          onTap: () => onTabChanged(0),
        ),
        if (isCreatorMode) ...[
          _TabItem(
            label: 'Collabs',
            iconData: HugeIcons.strokeRoundedUserGroup,
            isActive: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
          _TabItem(
            label: 'Songs',
            iconData: AppAssets.icon.music,
            isActive: selectedIndex == 2,
            onTap: () => onTabChanged(2),
          ),
        ] else ...[
          _TabItem(
            label: 'Playlists',
            iconData: AppAssets.icon.music,
            isActive: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final dynamic iconData;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.iconData,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData is IconData)
            Icon(iconData, color: color, size: 20)
          else
            HugeIcon(icon: iconData, color: color, size: 20.0),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
