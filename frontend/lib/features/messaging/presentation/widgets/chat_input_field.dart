import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: Container(
        // Adjusted padding to balance the multiline text and the circular button
        padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(30),
          // Optional: If you want the subtle border shown in the design, uncomment the next line
          // border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Keeps the send button at the bottom
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodySecondaryWhite.copyWith(fontSize: 14),
                minLines: 1,
                maxLines: 5, // Allows the field to grow up to 5 lines
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: AppStrings.messaging.writeMessageHint,
                  hintStyle: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  // Adjusted content padding for better vertical alignment
                  contentPadding: const EdgeInsets.only(top: 14, bottom: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSend,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 4,
                  top: 4,
                ), // Margins to float it nicely
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.greenDarkBg,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: AppAssets.icon.arrowUp,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
