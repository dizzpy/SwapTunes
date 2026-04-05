import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Defines the centralized typography styles for the SwapTunes application.
///
/// Contains all text styles mapped from Figma font tokens.
class AppTextStyles {
  // text.display.large: 39 SemiBold
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 39,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // text.heading.1: 31 SemiBold
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 31,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // text.heading.2: 25 SemiBold
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 25,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // text.heading.3: 20 SemiBold
  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // text.body.primary: 16 SemiBold
  static const TextStyle bodyPrimary = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // text.body.secondary: 13 Medium
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySecondaryWhite = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite,
  );

  static final TextStyle bodySecondary70 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite.withValues(alpha: 0.7),
  );

  // text.caption: 10 Regular
  static const TextStyle caption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // text.micro: 8 Medium
  static const TextStyle micro = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 8,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
