import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../data/models/chat_conversation_model.dart';
import '../widgets/chat_tile.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  // TODO: Replace with real conversations from backend / viewmodel
  static final List<ChatConversationModel> _mockConversations = [
    ChatConversationModel(
      id: '1',
      participantId: 'user-1',
      participantName: 'Dustin',
      participantAvatarUrl: 'https://i.pravatar.cc/150?img=11',
      isOnline: true,
      lastMessage: 'You gotta listen to this new track!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 8)),
      unreadCount: 3,
    ),
    ChatConversationModel(
      id: '2',
      participantId: 'user-2',
      participantName: 'Lucas',
      participantAvatarUrl: 'https://i.pravatar.cc/150?img=12',
      isOnline: false,
      lastMessage: 'That synth bass is killer!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 7)),
      unreadCount: 4,
    ),
    ChatConversationModel(
      id: '3',
      participantId: 'user-3',
      participantName: 'Max',
      participantAvatarUrl: 'https://i.pravatar.cc/150?img=5',
      isOnline: false,
      lastMessage: 'Totally vibing with this beat!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 6)),
      unreadCount: 2,
    ),
    ChatConversationModel(
      id: '4',
      participantId: 'user-4',
      participantName: 'Mike',
      participantAvatarUrl: 'https://i.pravatar.cc/150?img=13',
      isOnline: false,
      lastMessage: "It's got that retro feel, love it!",
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 1,
    ),
    ChatConversationModel(
      id: '5',
      participantId: 'user-5',
      participantName: 'Eleven',
      participantAvatarUrl: 'https://i.pravatar.cc/150?img=9',
      isOnline: false,
      lastMessage: 'Can we dance to this?',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 4)),
      unreadCount: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.messaging.chatsTitle,
                    style: AppTextStyles.heading2.copyWith(fontSize: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardFront,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: HugeIcon(
                      icon: AppAssets.icon.notification,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AppSearchBar(
                hintText: AppStrings.messaging.searchChatHint,
                borderWidth: 0,
              ),
            ),
            const SizedBox(height: 24),

            // Conversations Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                AppStrings.messaging.conversationsSection,
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // List of conversations
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                itemCount: _mockConversations.length,
                itemBuilder: (context, index) {
                  return ChatTile(conversation: _mockConversations[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
