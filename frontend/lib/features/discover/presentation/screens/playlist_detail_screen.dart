import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../data/models/source_platform.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/playlist_detail_viewmodel.dart';
import '../widgets/external_link_button.dart';
import 'playlist_editor_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  /// Must match the [PlaylistCard.heroTag] used to navigate here.
  final String? heroTag;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlaylistDetailViewModel(
        playlistId: playlistId,
        repository: ctx.read<DiscoverRepository>(),
        currentUserId: ctx.read<AuthViewmodel>().currentUser?.id,
      ),
      child: _PlaylistDetailContent(heroTag: heroTag),
    );
  }
}

class _PlaylistDetailContent extends StatelessWidget {
  final String? heroTag;

  const _PlaylistDetailContent({this.heroTag});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlaylistDetailViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: viewModel.isLoading
          ? const _PlaylistDetailShimmer()
          : viewModel.error != null
          ? _buildError(context, viewModel)
          : _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PlaylistDetailViewModel viewModel,
  ) {
    final playlist = viewModel.playlist!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: _buildOverlayButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            onTap: () => Navigator.pop(context),
          ),
          actions: playlist.isOwner
              ? [
                  _buildOverlayButton(
                    icon: HugeIcons.strokeRoundedEdit02,
                    onTap: () async {
                      final vm = context.read<PlaylistDetailViewModel>();
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaylistEditorScreen(playlistId: playlist.id),
                        ),
                      );
                      if (changed == true) vm.retry();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOverlayButton(
                    icon: HugeIcons.strokeRoundedDelete02,
                    onTap: () => _confirmDelete(context, viewModel),
                    isDestructive: true,
                  ),
                  const SizedBox(width: 16),
                ]
              : null,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCoverHero(playlist),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform badge
                _buildPlatformBadge(playlist.sourcePlatform),
                const SizedBox(height: 12),

                // Title row + like button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _LikeButton(viewModel: viewModel),
                  ],
                ),

                // Description
                if (playlist.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    playlist.description!,
                    style: AppTextStyles.bodySecondaryWhite.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Owner + date + track count row
                _buildMetaRow(playlist),

                const SizedBox(height: 20),

                // Hashtag genre tags (max 3)
                if (playlist.genreTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: playlist.genreTags
                        .take(3)
                        .map(
                          (tag) => Text(
                            '#${tag.toLowerCase()}',
                            style: AppTextStyles.bodySecondaryWhite.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── PRIMARY CTA ──────────────────────────────────────────
                if (playlist.primaryLink != null) ...[
                  _buildPrimaryCta(context, playlist.primaryLink!),
                  const SizedBox(height: 12),
                ],

                // Secondary platform links
                if (playlist.secondaryLinks.isNotEmpty) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: playlist.secondaryLinks
                        .map(
                          (entry) => ExternalLinkButton(
                            platform: entry.key,
                            onTap: () => AppHaptics.buttonTap(),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── TRACK LIST ───────────────────────────────────────────
                if (playlist.sourcePlatform == SourcePlatform.spotify)
                  _buildTrackList(viewModel),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildCoverHero(PlaylistDetailData playlist) {
    Widget coverImage = playlist.coverImageUrl != null
        ? Image.network(
            playlist.coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildCoverFallback(),
          )
        : _buildCoverFallback();

    if (heroTag != null) {
      coverImage = Hero(tag: heroTag!, child: coverImage);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        coverImage,
        // Fade to background at bottom so content reads cleanly
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.skeletonHighlight,
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedMusicNote01,
          color: AppColors.textSecondary,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(SourcePlatform platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: platform.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: platform.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        platform.displayName,
        style: AppTextStyles.caption.copyWith(
          color: platform.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetaRow(PlaylistDetailData playlist) {
    final day = playlist.createdAt.day;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '$day ${months[playlist.createdAt.month - 1]} ${playlist.createdAt.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Owner row
        Row(
          children: [
            ClipOval(
              child: playlist.ownerAvatarUrl != null
                  ? Image.network(
                      playlist.ownerAvatarUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
            const SizedBox(width: 8),
            Text(
              playlist.ownerFullName,
              style: AppTextStyles.bodySecondaryWhite.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '@${playlist.ownerUsername}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Date + track count
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              color: AppColors.textSecondary,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              '${AppStrings.discover.addedOnLabel} $dateStr',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedMusicNote01,
              color: AppColors.textSecondary,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              '${playlist.trackCount} ${AppStrings.discover.tracksCount}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 28,
      height: 28,
      color: AppColors.skeletonHighlight,
      child: const Icon(Icons.person, color: AppColors.textSecondary, size: 16),
    );
  }

  Widget _buildPrimaryCta(
    BuildContext context,
    MapEntry<SourcePlatform, String> link,
  ) {
    final platform = link.key;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => AppHaptics.buttonTap(),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedLink01,
          color: Colors.black,
          size: 18,
        ),
        label: Text(
          '${AppStrings.discover.openOn} ${platform.displayName}',
          style: AppTextStyles.bodyPrimary.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: platform.color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildTrackList(PlaylistDetailViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.discover.trackListLabel,
          style: AppTextStyles.bodyPrimary.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...viewModel.trackList.map((track) => _TrackRow(track: track)),
      ],
    );
  }

  Widget _buildOverlayButton({
    required dynamic icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: HugeIcon(
          icon: icon,
          color: isDestructive ? AppColors.danger : AppColors.textWhite,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PlaylistDetailViewModel viewModel,
  ) async {
    AppHaptics.buttonTap();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.discover.deletePlaylist,
      message: AppStrings.discover.deletePlaylistMessage,
      confirmLabel: AppStrings.discover.deletePlaylist,
      isDanger: true,
    );
    if (confirmed == true && context.mounted) {
      AppHaptics.buttonTap();
      final success = await viewModel.deletePlaylist();
      if (success && context.mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildError(BuildContext context, PlaylistDetailViewModel viewModel) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.textWhite),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.discover.loadingError,
              style: AppTextStyles.bodySecondaryWhite.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: viewModel.retry,
              child: Text(
                AppStrings.discover.retry,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Like button widget ────────────────────────────────────────────────────────

class _LikeButton extends StatelessWidget {
  final PlaylistDetailViewModel viewModel;

  const _LikeButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.buttonTap();
        viewModel.toggleLike();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: viewModel.isLiked
              ? AppColors.danger.withValues(alpha: 0.12)
              : AppColors.cardFront,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: viewModel.isLiked
                ? AppColors.danger.withValues(alpha: 0.4)
                : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              viewModel.isLiked ? Icons.favorite : Icons.favorite_border,
              color: viewModel.isLiked
                  ? AppColors.danger
                  : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '${viewModel.likeCount}',
              style: AppTextStyles.caption.copyWith(
                color: viewModel.isLiked
                    ? AppColors.danger
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _PlaylistDetailShimmer extends StatelessWidget {
  const _PlaylistDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image area
            const ShimmerBox(width: double.infinity, height: 320, radius: 0),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform badge
                  const ShimmerBox(width: 80, height: 24, radius: 8),
                  const SizedBox(height: 12),
                  // Title
                  const ShimmerBox(width: 220, height: 26, radius: 8),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 160, height: 20, radius: 8),
                  const SizedBox(height: 16),
                  // Description
                  const ShimmerBox(width: double.infinity, height: 14, radius: 6),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 240, height: 14, radius: 6),
                  const SizedBox(height: 24),
                  // Owner row
                  const Row(
                    children: [
                      ShimmerCircle(size: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 130, height: 14, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // CTA button
                  const ShimmerBox(width: double.infinity, height: 52, radius: 16),
                  const SizedBox(height: 28),
                  // Track list header
                  const ShimmerBox(width: 80, height: 16, radius: 6),
                  const SizedBox(height: 12),
                  // Track rows
                  ...List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          ShimmerBox(width: 28, height: 14, radius: 4),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(height: 14, radius: 6),
                                SizedBox(height: 4),
                                ShimmerBox(width: 100, height: 11, radius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track row widget ──────────────────────────────────────────────────────────

class _TrackRow extends StatelessWidget {
  final TrackItem track;

  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${track.index}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTextStyles.bodySecondaryWhite.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
