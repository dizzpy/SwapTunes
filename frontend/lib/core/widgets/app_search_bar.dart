import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;

  // --- Extracted Layout Variables ---
  final double borderRadius;
  final double borderWidth;
  final double iconSize;
  final double horizontalPadding;
  final double iconSpacing;
  final double verticalPadding;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search user, playlists...',
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.borderRadius = 18.0,
    this.borderWidth = 1.0,
    this.iconSize = 20.0,
    this.horizontalPadding = 20.0,
    this.iconSpacing = 10.0,
    this.verticalPadding = 19.0,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: AppTextStyles.bodySecondaryWhite,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySecondary,
        filled: true,
        fillColor: AppColors.cardFront,
        contentPadding: EdgeInsets.only(
          top: verticalPadding,
          bottom: verticalPadding,
          right: horizontalPadding,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: horizontalPadding, right: iconSpacing),
          child: HugeIcon(
            icon: AppAssets.icon.search,
            color: AppColors.textSecondary,
            size: iconSize,
          ),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: horizontalPadding + iconSpacing + iconSize,
          minHeight: iconSize,
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: horizontalPadding, left: iconSpacing),
          child: GestureDetector(
            onTap:
                onClear ??
                () {
                  controller?.clear();
                  if (onChanged != null) {
                    onChanged!('');
                  }
                },
            child: HugeIcon(
              icon: AppAssets.icon.cancelCircle,
              color: AppColors.textSecondary,
              size: iconSize,
            ),
          ),
        ),
        suffixIconConstraints: BoxConstraints(
          minWidth: horizontalPadding + iconSpacing + iconSize,
          minHeight: iconSize,
        ),
        border: _outlineBorder(),
        enabledBorder: _outlineBorder(),
        focusedBorder: _outlineBorder(
          borderSide: BorderSide(color: AppColors.primary, width: borderWidth),
        ),
      ),
    );
  }

  OutlineInputBorder _outlineBorder({BorderSide? borderSide}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide:
          borderSide ??
          BorderSide(color: AppColors.outline, width: borderWidth),
    );
  }
}
