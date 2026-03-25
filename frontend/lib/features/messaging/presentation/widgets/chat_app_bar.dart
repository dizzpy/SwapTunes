import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/chat_conversation_model.dart';

class ChatAppBar extends StatelessWidget {
  final ChatConversationModel conversation;

  const ChatAppBar({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        // Tuned padding to keep the back arrow close to the left edge like the design
        padding: const EdgeInsets.only(left: 8, right: 12, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: HugeIcon(
                icon: AppAssets.icon.arrowLeft,
                color: AppColors.textWhite,
                size: 20,
              ),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),

            // Avatar
            Hero(
              tag: 'avatar-${conversation.participantId}',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: conversation.participantAvatarUrl != null
                      ? DecorationImage(
                          image:
                              NetworkImage(conversation.participantAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: conversation.participantAvatarUrl == null
                      ? AppColors.outline
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // Keeps the texts stacked tightly
                children: [
                  Text(
                    conversation.participantName,
                    style: AppTextStyles.bodyPrimary,
                  ),
                  const SizedBox(
                    height: 2,
                  ), // Tight vertical spacing matching Figma
                  Text(
                    conversation.isOnline
                        ? AppStrings.messaging.onlineStatus
                        : AppStrings.messaging.offlineStatus,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: conversation.isOnline
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // More Options
            IconButton(
              icon: HugeIcon(
                icon: AppAssets.icon.more,
                color: AppColors.textWhite,
                size: 24,
              ),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
