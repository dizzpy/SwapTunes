import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A custom confirmation dialog matching the SwapTunes dark UI.
///
/// Returns `true` when the user confirms, `false` / `null` when dismissed.
///
/// Usage:
///   final confirmed = await AppConfirmDialog.show(
///     context,
///     title: 'Delete post',
///     message: 'This post will be permanently removed.',
///     confirmLabel: 'Delete',
///     isDanger: true,
///   );
///   if (confirmed == true) { ... }
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
  });

  /// Convenience method to show the dialog and await the result.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDanger ? AppColors.danger : AppColors.primary;

    return AlertDialog(
      backgroundColor: AppColors.cardFront,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Text(title, style: AppTextStyles.heading3),
      content: Text(
        message,
        style: AppTextStyles.bodyPrimary.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: AppTextStyles.bodyPrimary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: AppTextStyles.bodyPrimary.copyWith(color: confirmColor),
          ),
        ),
      ],
    );
  }
}
