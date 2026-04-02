import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../feed/presentation/screens/main_layout_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../messaging/data/models/chat_conversation_model.dart';
import '../../../messaging/presentation/screens/single_chat_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/models/collab_model.dart';
import '../viewmodels/collab_viewmodel.dart';
import '../widgets/tag_chip.dart';
import 'new_collaboration_screen.dart';

/// Detail screen for a single collaboration post.
///
/// Accepts only a [collabId] and loads data from [CollabViewmodel].
class CollabDetailsScreen extends StatefulWidget {
  final String collabId;

  const CollabDetailsScreen({super.key, required this.collabId});

  @override
  State<CollabDetailsScreen> createState() => _CollabDetailsScreenState();
}

class _CollabDetailsScreenState extends State<CollabDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MainLayoutScreen.hideNavBar();
      context.read<CollabViewmodel>().loadCollabById(widget.collabId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainLayoutScreen.showNavBar();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, CollabViewmodel vm) {
    if (vm.isDetailLoading) {
      return const _LoadingState();
    }

    if (vm.detailError != null) {
      return _ErrorState(
        message: vm.detailError!,
        onRetry: () =>
            context.read<CollabViewmodel>().loadCollabById(widget.collabId),
      );
    }

    if (vm.selectedCollab == null) {
      return const _LoadingState();
    }

    final currentUserId = context.read<StorageService>().getUserId() ?? '';
    final isOwn = vm.selectedCollab!.creatorId == currentUserId;

    return _Content(collab: vm.selectedCollab!, isOwn: isOwn);
  }
}

class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppIconButton(
              icon: AppAssets.icon.arrowLeft,
              onTap: () => Navigator.pop(context),
              variant: AppIconButtonVariant.filled,
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return _ShimmerContent(progress: _shimmerController.value);
        },
      ),
    );
  }
}

class _ShimmerContent extends StatelessWidget {
  final double progress;

  const _ShimmerContent({required this.progress});

  Widget _block({
    double width = double.infinity,
    double height = 16,
    double radius = 10,
  }) {
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        AppColors.skeletonBase,
        AppColors.skeletonHighlight,
        AppColors.skeletonBase,
      ],
      stops: [
        (progress - 0.3).clamp(0.0, 1.0),
        progress.clamp(0.0, 1.0),
        (progress + 0.3).clamp(0.0, 1.0),
      ],
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author card skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                _block(width: 56, height: 56, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(width: 120, height: 14),
                      const SizedBox(height: 8),
                      _block(width: 80, height: 12),
                    ],
                  ),
                ),
                _block(width: 72, height: 34, radius: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Title
          _block(height: 22),
          const SizedBox(height: 10),
          _block(width: 180, height: 22),
          const SizedBox(height: 20),
          // Badges row
          Row(
            children: [
              _block(width: 110, height: 34, radius: 8),
              const SizedBox(width: 12),
              _block(width: 90, height: 34, radius: 8),
            ],
          ),
          const SizedBox(height: 28),
          // About section title
          _block(width: 120, height: 14),
          const SizedBox(height: 12),
          _block(height: 13),
          const SizedBox(height: 8),
          _block(height: 13),
          const SizedBox(height: 8),
          _block(width: 220, height: 13),
          const SizedBox(height: 28),
          // Looking for title
          _block(width: 100, height: 14),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _block(width: 80, height: 32, radius: 20),
              _block(width: 100, height: 32, radius: 20),
              _block(width: 70, height: 32, radius: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppIconButton(
              icon: AppAssets.icon.arrowLeft,
              onTap: () => Navigator.pop(context),
              variant: AppIconButtonVariant.filled,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  AppStrings.collab.retry,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final CollabModel collab;
  final bool isOwn;

  const _Content({required this.collab, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            leadingWidth: 64,
            leading: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: AppIconButton(
                  icon: AppAssets.icon.arrowLeft,
                  onTap: () => Navigator.pop(context),
                  variant: AppIconButtonVariant.filled,
                ),
              ),
            ),
            title: Text(
              AppStrings.collab.detailTitle,
              style: AppTextStyles.heading3,
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthorCard(collab: collab, isOwn: isOwn),
                  const SizedBox(height: 24),
                  Text(collab.title, style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  _ProjectTypeBadge(collab: collab),
                  const SizedBox(height: 24),
                  _Section(
                    title: AppStrings.collab.aboutProject,
                    child: Text(
                      collab.description,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (collab.lookingFor.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Section(
                      title: AppStrings.collab.lookingForSection,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: collab.lookingFor
                            .map(
                              (r) => TagChip(
                                label: r,
                                isSelected: true,
                                showBorder: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (collab.genreStyle.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Section(
                      title: AppStrings.collab.genresSection,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: collab.genreStyle
                            .map(
                              (g) => TagChip(
                                label: g,
                                isSelected: false,
                                showBorder: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(collab: collab, isOwn: isOwn),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  final CollabModel collab;
  final bool isOwn;

  const _AuthorCard({required this.collab, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: collab.creatorAvatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collab.creatorFullName,
                  style: AppTextStyles.bodyPrimary.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${collab.creatorUsername}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          if (isOwn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardFront,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedPencilEdit01,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppStrings.collab.yourPost,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) =>
                      UserProfileScreen(username: collab.creatorUsername),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.collab.viewProfile,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
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
      width: 56,
      height: 56,
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
                  size: 28,
                ),
              )
            : const ColoredBox(
                color: AppColors.skeletonBase,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 28,
                ),
              ),
      ),
    );
  }
}

class _ProjectTypeBadge extends StatelessWidget {
  final CollabModel collab;

  const _ProjectTypeBadge({required this.collab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase01,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                collab.paymentTypeLabel,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(collab.timeAgo, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyPrimary.copyWith(fontSize: 17)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CollabModel collab;
  final bool isOwn;

  const _BottomBar({required this.collab, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: isOwn
            ? _OwnPostActions(collab: collab)
            : _MessageAction(collab: collab),
      ),
    );
  }
}

// ── Bottom bar actions ─────────────────────────────────────────────────────

class _MessageAction extends StatelessWidget {
  final CollabModel collab;

  const _MessageAction({required this.collab});

  @override
  Widget build(BuildContext context) {
    return GreenButton(
      text: '${AppStrings.collab.messageButton} ${collab.creatorFullName}',
      height: 56,
      onPressed: () {
        final tempConversation = ChatConversationModel(
          id: '',
          participantId: collab.creatorId,
          participantName: collab.creatorFullName,
          participantAvatarUrl: collab.creatorAvatarUrl,
          isOnline: false,
          lastMessage: '',
          lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
          unreadCount: 0,
        );
        final preFilledMessage =
            'Hey @${collab.creatorUsername}! 👋 I just came across your "${collab.title}" collab and I\'m really interested in working together on this. Would love to chat more about it! 🎵';

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => SingleChatScreen(
              conversation: tempConversation,
              recipientId: collab.creatorId,
              initialMessage: preFilledMessage,
              collabTitle: collab.title,
              collabCreator: collab.creatorUsername,
            ),
          ),
        );
      },
    );
  }
}

class _OwnPostActions extends StatelessWidget {
  final CollabModel collab;

  const _OwnPostActions({required this.collab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedAppButton(
            text: AppStrings.collab.editPost,
            height: 56,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit01,
              color: AppColors.primary,
              size: 18,
            ),
            borderColor: AppColors.primary,
            textColor: AppColors.primary,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NewCollaborationScreen(existingCollab: collab),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedAppButton(
            text: AppStrings.collab.deletePost,
            height: 56,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: AppColors.danger,
              size: 18,
            ),
            borderColor: AppColors.danger,
            textColor: AppColors.danger,
            onPressed: () async {
              final confirmed = await AppConfirmDialog.show(
                context,
                title: AppStrings.collab.deleteDialogTitle,
                message: AppStrings.collab.deleteConfirmMessage,
                confirmLabel: AppStrings.collab.deleteDialogConfirm,
                isDanger: true,
              );
              if (confirmed != true || !context.mounted) return;

              final success = await context
                  .read<CollabViewmodel>()
                  .deleteCollab(collab.id);
              if (!context.mounted) return;

              if (success) {
                AppSnackbar.success(AppStrings.collab.deleteSuccess);
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                AppSnackbar.error(AppStrings.collab.deleteError);
              }
            },
          ),
        ),
      ],
    );
  }
}
