import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../messaging/data/models/chat_conversation_model.dart';
import '../../../messaging/presentation/screens/single_chat_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/models/collab_match_result.dart';

class MatchCard extends StatelessWidget {
  final CollabMatchResult match;
  final String collabTitle;

  const MatchCard({super.key, required this.match, required this.collabTitle});

  @override
  Widget build(BuildContext context) {
    final profile = match.profile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(imageUrl: profile.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${profile.username}',
                      style: AppTextStyles.bodyPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.roleTitle,
                      style: AppTextStyles.bodySecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MatchScoreBadge(score: match.matchScore),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match.reason,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedAppButton(
                  text: AppStrings.collab.matchViewProfile,
                  height: 44,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(username: profile.username),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GreenButton(
                  text: AppStrings.collab.messageButton,
                  height: 44,
                  onPressed: () {
                    final tempConversation = ChatConversationModel(
                      id: '',
                      participantId: match.userId,
                      participantName: profile.username,
                      participantUsername: profile.username,
                      participantAvatarUrl: profile.avatarUrl,
                      isOnline: false,
                      lastMessage: '',
                      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
                      unreadCount: 0,
                    );
                    final preFilledMessage =
                        'Hey @${profile.username}! 👋 SwapTunes AI matched us ${match.matchScore}% compatible for my "$collabTitle" collab. '
                        'Based on your profile as ${profile.roleTitle}, I think we could create something really special together. '
                        'Would love to connect and explore this! 🎵';

                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => SingleChatScreen(
                          conversation: tempConversation,
                          recipientId: match.userId,
                          initialMessage: preFilledMessage,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;

  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.skeletonBase),
                errorWidget: (_, _, _) => const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              )
            : const ColoredBox(
                color: AppColors.skeletonBase,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  final int score;

  const _MatchScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedStars,
            color: AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$score${AppStrings.collab.matchScoreSuffix}',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
