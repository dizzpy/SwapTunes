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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline, width: 0.8),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: AppTextStyles.bodyPrimary.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Message
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.outline,
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cancelLabel,
                        style: AppTextStyles.bodyPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDanger
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : AppColors.greenDarkBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: confirmColor, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: confirmColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
