import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// BASE
// ─────────────────────────────────────────────

abstract class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final double height;
  final double borderRadius;
  final Color? foregroundColor;

  const BaseButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.height = 52.0,
    this.borderRadius = 18.0,
    this.foregroundColor,
  });

  ButtonStyle buildStyle(BuildContext context);

  Widget buildLabel() {
    final label = Text(
      text,
      style: AppTextStyles.bodyPrimary.copyWith(
        color: foregroundColor,
        fontSize: 15,
      ),
    );

    if (icon == null) return label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [icon!, const SizedBox(width: 8), label],
    );
  }

  Widget buildChild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: buildChild(context),
    );
  }
}

// ─────────────────────────────────────────────
// PRIMARY
// ─────────────────────────────────────────────

class PrimaryButton extends BaseButton {
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.height,
    super.borderRadius,
    this.backgroundColor,
    super.foregroundColor,
  });

  @override
  ButtonStyle buildStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: backgroundColor ?? AppColors.textWhite,
    foregroundColor: foregroundColor ?? AppColors.background,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  @override
  Widget buildChild(BuildContext context) => ElevatedButton(
    style: buildStyle(context),
    onPressed: onPressed,
    child: buildLabel(),
  );
}

// ─────────────────────────────────────────────
// OUTLINED
// ─────────────────────────────────────────────

class OutlinedAppButton extends BaseButton {
  final BorderSide? border;

  const OutlinedAppButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.height,
    super.borderRadius,
    super.foregroundColor,
    this.border,
  });

  @override
  ButtonStyle buildStyle(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: foregroundColor ?? AppColors.textSecondary,
    side: border ?? const BorderSide(color: AppColors.outline, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  @override
  Widget buildChild(BuildContext context) => OutlinedButton(
    style: buildStyle(context),
    onPressed: onPressed,
    child: buildLabel(),
  );
}

// ─────────────────────────────────────────────
// SOCIAL
// ─────────────────────────────────────────────

class SocialButton extends BaseButton {
  final Color backgroundColor;

  const SocialButton({
    super.key,
    required super.text,
    required super.onPressed,
    required super.icon,
    required this.backgroundColor,
    required Color foregroundColor,
    super.height,
    super.borderRadius,
  }) : super(foregroundColor: foregroundColor);

  @override
  ButtonStyle buildStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  @override
  Widget buildChild(BuildContext context) => ElevatedButton(
    style: buildStyle(context),
    onPressed: onPressed,
    child: buildLabel(),
  );
}

// ─────────────────────────────────────────────
// GREEN (Dark tinted, music-themed)
// ─────────────────────────────────────────────

/// A music-themed green button using the translucent green background.
/// Ideal for primary actions within music/playlist contexts.
class GreenButton extends BaseButton {
  const GreenButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.icon,
    super.height,
    super.borderRadius,
  }) : super(foregroundColor: AppColors.primary);

  @override
  ButtonStyle buildStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.greenDarkBg,
    foregroundColor: AppColors.primary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.25),
        width: 1,
      ),
    ),
  );

  @override
  Widget buildChild(BuildContext context) => ElevatedButton(
    style: buildStyle(context),
    onPressed: onPressed,
    child: buildLabel(),
  );
}
