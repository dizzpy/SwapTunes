import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A single-field text input dialog matching the SwapTunes dark UI.
///
/// Returns the trimmed string when the user saves, or `null` when dismissed.
/// An empty save is treated as a clear and returns an empty string so callers
/// can distinguish "cancel" (null) from "clear" ('').
class AppInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String saveLabel;
  final String cancelLabel;
  final TextInputType keyboardType;
  final bool obscure;

  const AppInputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String saveLabel = 'Save',
    String cancelLabel = 'Cancel',
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AppInputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        saveLabel: saveLabel,
        cancelLabel: cancelLabel,
        keyboardType: keyboardType,
        obscure: obscure,
      ),
    );
  }

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardFront,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Text(widget.title, style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: AppTextStyles.bodyPrimary.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscure,
            autofocus: true,
            style: AppTextStyles.bodyPrimary,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.cancelLabel,
            style: AppTextStyles.bodyPrimary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(
            widget.saveLabel,
            style: AppTextStyles.bodyPrimary.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
