import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';

/// Matches the variants defined in Figma: filled, empty, colored, rounded
enum AppIconButtonVariant { filled, empty, colored, rounded }

class AppIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback? onTap;
  final AppIconButtonVariant variant;
  // Always square — only one size param to enforce 1:1 ratio everywhere.
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.variant = AppIconButtonVariant.filled,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color? borderColor;
    double borderRadiusValue = 16.0; // Figma "Rounded" look
    BoxShape shape = BoxShape.rectangle;

    switch (variant) {
      case AppIconButtonVariant.filled:
        // Dark grey container with subtle border
        bgColor = AppColors.cardFront;
        borderColor = AppColors.outline.withValues(alpha: 0.5);
        break;
      case AppIconButtonVariant.empty:
        // No background, no border
        bgColor = Colors.transparent;
        borderColor = null;
        break;
      case AppIconButtonVariant.colored:
        // Primary brand color (Green/Teal in design)
        bgColor = AppColors.primary;
        borderColor = null;
        break;
      case AppIconButtonVariant.rounded:
        // Circular dark grey button
        bgColor = AppColors.cardFront;
        borderColor = AppColors.outline.withValues(alpha: 0.5);
        shape = BoxShape.circle;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) onTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadiusValue),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.2)
              : null,
        ),
        child: Center(child: _buildIcon()),
      ),
    );
  }

  Widget _buildIcon() {
    // Determine icon color based on background
    Color iconColor = variant == AppIconButtonVariant.colored
        ? Colors.white
        : AppColors.textWhite;

    if (icon is IconData) {
      return Icon(icon, color: iconColor, size: iconSize);
    } else {
      return HugeIcon(icon: icon, color: iconColor, size: iconSize);
    }
  }
}
