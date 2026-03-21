import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/navigation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Global snackbar utility. Works without a BuildContext by using
/// [NavigationService.navigatorKey].
///
/// Usage:
///   AppSnackbar.success('Post deleted');
///   AppSnackbar.error('Something went wrong');
class AppSnackbar {
  AppSnackbar._();

  static void success(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
    iconColor: AppColors.primary,
  );

  static void error(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedAlert02,
    iconColor: AppColors.danger,
  );

  static void info(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedInformationCircle,
    iconColor: AppColors.textSecondary,
  );

  static void _show({
    required String message,
    required dynamic icon,
    required Color iconColor,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline, width: 0.8),
            ),
            child: Row(
              children: [
                HugeIcon(icon: icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: AppTextStyles.bodySecondaryWhite),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
