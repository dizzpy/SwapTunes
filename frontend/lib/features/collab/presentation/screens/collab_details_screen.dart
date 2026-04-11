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
import 'collab_match_loading_screen.dart';
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
        title: Text(
          AppStrings.collab.detailTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) =>
            _ShimmerBottomBar(progress: _shimmerController.value),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author card — avatar + name/username/time + view profile button
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
                      _block(width: 130, height: 14),
                      const SizedBox(height: 8),
                      _block(width: 110, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _block(width: 95, height: 34, radius: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Title (heading2) — two lines
          _block(height: 24),
          const SizedBox(height: 10),
          _block(width: 200, height: 24),
          const SizedBox(height: 16),
          // MetadataRow — single payment chip
          _block(width: 140, height: 36, radius: 8),
          const SizedBox(height: 24),
          // About card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 150, height: 16),
                const SizedBox(height: 12),
                _block(height: 13),
                const SizedBox(height: 8),
                _block(height: 13),
                const SizedBox(height: 8),
                _block(width: 240, height: 13),
                const SizedBox(height: 8),
                _block(width: 180, height: 13),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Looking For section
          _block(width: 110, height: 16),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _block(width: 80, height: 32, radius: 20),
              _block(width: 100, height: 32, radius: 20),
              _block(width: 70, height: 32, radius: 20),
              _block(width: 90, height: 32, radius: 20),
            ],
          ),
          const SizedBox(height: 24),
          // Genres section
          _block(width: 80, height: 16),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _block(width: 90, height: 32, radius: 20),
              _block(width: 75, height: 32, radius: 20),
              _block(width: 110, height: 32, radius: 20),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _ShimmerBottomBar extends StatelessWidget {
  final double progress;

  const _ShimmerBottomBar({required this.progress});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
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
            actions: isOwn
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _OverflowMenu(collab: collab),
                    ),
                  ]
                : null,
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
                  _MetadataRow(collab: collab),
                  const SizedBox(height: 24),
                  _AboutCard(
                    child: _Section(
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
                  // Single consistent bottom padding for both views
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

// ── Author card with overflow menu for own posts ───────────────────────────

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        collab.creatorFullName,
                        style: AppTextStyles.bodyPrimary.copyWith(fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppStrings.collab.yourPost,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '@${collab.creatorUsername}',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '·',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      collab.timeAgo,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isOwn)
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

// ── Three-dot overflow menu (Edit / Delete) ────────────────────────────────

class _OverflowMenu extends StatelessWidget {
  final CollabModel collab;

  const _OverflowMenu({required this.collab});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OverflowAction>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: const Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedMoreVertical,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      color: AppColors.cardFront,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      offset: const Offset(0, 48),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _OverflowAction.edit,
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit01,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.collab.editPost,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _OverflowAction.delete,
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.collab.deletePost,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, _OverflowAction action) {
    switch (action) {
      case _OverflowAction.edit:
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => NewCollaborationScreen(existingCollab: collab),
          ),
        );
      case _OverflowAction.delete:
        _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.collab.deleteDialogTitle,
      message: AppStrings.collab.deleteConfirmMessage,
      confirmLabel: AppStrings.collab.deleteDialogConfirm,
      isDanger: true,
    );
    if (confirmed != true || !context.mounted) return;

    final success = await context.read<CollabViewmodel>().deleteCollab(
      collab.id,
    );
    if (!context.mounted) return;

    if (success) {
      AppSnackbar.success(AppStrings.collab.deleteSuccess);
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      AppSnackbar.error(AppStrings.collab.deleteError);
    }
  }
}

enum _OverflowAction { edit, delete }

// ── Metadata row: payment chip + plain time text ───────────────────────────

class _MetadataRow extends StatelessWidget {
  final CollabModel collab;

  const _MetadataRow({required this.collab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Payment type — prominent filled chip
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
      ],
    );
  }
}

// ── About section wrapped in a card ────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  final Widget child;

  const _AboutCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: child,
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

// ── Clean bottom bar — single CTA for both views ──────────────────────────

class _BottomBar extends StatelessWidget {
  final CollabModel collab;
  final bool isOwn;

  const _BottomBar({required this.collab, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: isOwn
          ? _FindMatchesAction(collab: collab)
          : _MessageAction(collab: collab),
    );
  }
}

// ── Single CTA: Find Matching Creators (own post) ─────────────────────────

class _FindMatchesAction extends StatelessWidget {
  final CollabModel collab;

  const _FindMatchesAction({required this.collab});

  @override
  Widget build(BuildContext context) {
    return GreenButton(
      text: AppStrings.collab.findMatchesButton,
      height: 56,
      onPressed: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CollabMatchLoadingScreen(
              collabId: collab.id,
              collabTitle: collab.title,
            ),
          ),
        );
      },
    );
  }
}

// ── Single CTA: Message (public post) ─────────────────────────────────────

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
          participantUsername: collab.creatorUsername,
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
