import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isSent;
  final bool isFirst;
  final bool isLast;
  final bool isDeleted;
  final VoidCallback? onLongPress;

  /// Delivery state for outgoing messages. Null for received / persisted messages.
  final MessageStatus? status;

  /// Called when the user taps the retry indicator on a [MessageStatus.failed] message.
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isSent,
    this.isFirst = true,
    this.isLast = true,
    this.isDeleted = false,
    this.onLongPress,
    this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(!isSent && !isFirst ? 4 : 18),
      topRight: Radius.circular(isSent && !isFirst ? 4 : 18),
      bottomLeft: Radius.circular(!isSent && !isLast ? 4 : 18),
      bottomRight: Radius.circular(isSent && !isLast ? 4 : 18),
    );

    final bubble = GestureDetector(
      onLongPress: (!isDeleted && isSent) ? onLongPress : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSent ? AppColors.greenDarkBg : AppColors.receivedBubbleBg,
          borderRadius: borderRadius,
        ),
        child: isDeleted
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppStrings.messaging.messageDeletedPlaceholder,
                    style: AppTextStyles.bodySecondaryWhite.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: AppTextStyles.bodySecondaryWhite.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
      ),
    );

    // Status indicator — only shown on failure so the user can retry.
    Widget? statusIndicator;
    if (isSent && status == MessageStatus.failed) {
      statusIndicator = GestureDetector(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 12, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                'Tap to retry',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: statusIndicator == null
          ? bubble
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [bubble, statusIndicator],
            ),
    );
  }
}
