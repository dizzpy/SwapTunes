import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isSent;
  final bool isFirst;
  final bool isLast;
  final bool isDeleted;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isSent,
    this.isFirst = true,
    this.isLast = true,
    this.isDeleted = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(!isSent && !isFirst ? 4 : 18),
      topRight: Radius.circular(isSent && !isFirst ? 4 : 18),
      bottomLeft: Radius.circular(!isSent && !isLast ? 4 : 18),
      bottomRight: Radius.circular(isSent && !isLast ? 4 : 18),
    );

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
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
      ),
    );
  }
}
