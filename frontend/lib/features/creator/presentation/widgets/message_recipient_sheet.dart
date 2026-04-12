import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../collab/data/models/collab_match_result.dart';
import '../../../collab/presentation/viewmodels/collab_match_viewmodel.dart';
import '../../../messaging/data/models/chat_conversation_model.dart';
import '../../../messaging/presentation/screens/single_chat_screen.dart';
import '../viewmodels/song_builder_viewmodel.dart';

/// Bottom sheet shown when creator taps "Send via Message" on the result screen.
///
/// Auto-suggests creators from [CollabMatchViewModel]'s cached matches,
/// then falls back to a search field for all creators.
class MessageRecipientSheet extends StatefulWidget {
  const MessageRecipientSheet({super.key});

  @override
  State<MessageRecipientSheet> createState() => _MessageRecipientSheetState();
}

class _MessageRecipientSheetState extends State<MessageRecipientSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _sendToMatch(BuildContext context, CollabMatchResult match) {
    final result = context.read<SongBuilderViewModel>().result;
    Navigator.pop(context); // close sheet

    String conceptText = '';
    if (result != null) {
      final structureSummary = result.sections
          .take(4)
          .map((s) => s.name)
          .join(' → ');
      conceptText = '🎵 "${result.title}"\n\n'
          '${result.sampleHook != null ? '🎤 Hook: "${result.sampleHook}"\n\n' : ''}'
          '📋 Structure: $structureSummary${result.sections.length > 4 ? '...' : ''}\n\n'
          'Would love to collab on this with you!';
    }

    final tempConversation = ChatConversationModel(
      id: '',
      participantId: match.userId,
      participantName: match.profile.username,
      participantUsername: match.profile.username,
      participantAvatarUrl: match.profile.avatarUrl,
      isOnline: false,
      lastMessage: '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: 0,
    );

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SingleChatScreen(
          conversation: tempConversation,
          recipientId: match.userId,
          initialMessage: conceptText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collabMatches = context.watch<CollabMatchViewModel>().matches;

    // Filter matches by search query if user typed something
    final filteredMatches = _query.isEmpty
        ? collabMatches
        : collabMatches
            .where((m) =>
                m.profile.username.toLowerCase().contains(_query) ||
                m.profile.roleTitle.toLowerCase().contains(_query))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.songBuilder.recipientSheetTitle,
                  style: AppTextStyles.heading3,
                ),
              ),
              const SizedBox(height: 16),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTextStyles.bodyPrimary,
                  decoration: InputDecoration(
                    hintText: AppStrings.songBuilder.searchHint,
                    hintStyle: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── List ──
              Expanded(
                child: filteredMatches.isEmpty
                    ? _EmptyState(hasQuery: _query.isNotEmpty)
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          if (_query.isEmpty) ...[
                            Text(
                              AppStrings.songBuilder.suggestedSection,
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          ...filteredMatches.map(
                            (match) => _RecipientRow(
                              match: match,
                              onSend: () => _sendToMatch(context, match),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  RECIPIENT ROW
// ─────────────────────────────────────────────

class _RecipientRow extends StatelessWidget {
  final CollabMatchResult match;
  final VoidCallback onSend;

  const _RecipientRow({required this.match, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final profile = match.profile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Match score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${match.matchScore}%',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.songBuilder.sendAction,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AVATAR
// ─────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? imageUrl;

  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.3),
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
                  size: 22,
                ),
              )
            : const ColoredBox(
                color: AppColors.skeletonBase,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.people_outline,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'No creators found'
                  : AppStrings.songBuilder.noSuggestions,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 6),
              Text(
                AppStrings.songBuilder.noSuggestionsSubtitle,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
