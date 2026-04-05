import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/chat_conversation_model.dart';
import '../screens/single_chat_screen.dart';

class ChatTile extends StatelessWidget {
  final ChatConversationModel conversation;
  final VoidCallback? onReturn;

  const ChatTile({super.key, required this.conversation, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => SingleChatScreen(conversation: conversation),
        ),
      ).then((_) => onReturn?.call()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'avatar-${conversation.participantId}',
              child: Container(
                width: 50,
                height: 50,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.participantName,
                    style: AppTextStyles.bodyPrimary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.timeAgo,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                if (conversation.unreadCount > 0)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.greenDarkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
