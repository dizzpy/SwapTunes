import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer.dart';
import '../widgets/genre_chip.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/featured_playlists_viewmodel.dart';
import '../widgets/playlist_card.dart';
import 'playlist_detail_screen.dart';

class FeaturedPlaylistsScreen extends StatelessWidget {
  const FeaturedPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          FeaturedPlaylistsViewModel(ctx.read<DiscoverRepository>()),
      child: const _FeaturedPlaylistsContent(),
    );
  }
}

class _FeaturedPlaylistsContent extends StatefulWidget {
  const _FeaturedPlaylistsContent();

  @override
  State<_FeaturedPlaylistsContent> createState() =>
      _FeaturedPlaylistsContentState();
}

class _FeaturedPlaylistsContentState extends State<_FeaturedPlaylistsContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.offset >= threshold) {
      context.read<FeaturedPlaylistsViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FeaturedPlaylistsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Genre filter chips ──────────────────────────
          if (viewModel.genres.isNotEmpty)
            _buildGenreFilters(viewModel),

          // ── Content ─────────────────────────────────────
          Expanded(
            child: viewModel.isLoading
                ? const _PlaylistGridShimmer()
                : viewModel.error != null
                ? _buildError(context, viewModel)
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardFront,
                    onRefresh: viewModel.refresh,
                    child: viewModel.playlists.isEmpty
                        ? _buildEmpty()
                        : _buildGrid(context, viewModel),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilters(FeaturedPlaylistsViewModel viewModel) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.genres.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GenreChip(
              label: 'All',
              isSelected: viewModel.activeGenre == null,
              onTap: () => viewModel.setGenre(null),
            );
          }
          final genre = viewModel.genres[index - 1];
          return GenreChip(
            label: genre,
            isSelected: viewModel.activeGenre == genre,
            onTap: () => viewModel.setGenre(genre),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        'Featured Playlists',
        style: AppTextStyles.heading3.copyWith(color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    FeaturedPlaylistsViewModel viewModel,
  ) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: viewModel.playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == viewModel.playlists.length) {
          return _buildFooter(viewModel);
        }
        final playlist = viewModel.playlists[index];
        return PlaylistCard(
          title: playlist.name,
          subtitle: playlist.genreTags.isNotEmpty
              ? playlist.genreTags.join(', ')
              : playlist.ownerUsername,
          imageUrl: playlist.coverImageUrl,
          heroTag: playlist.id,
          onTap: () async {
            final vm = context.read<FeaturedPlaylistsViewModel>();
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                  playlistId: playlist.id,
                  heroTag: playlist.id,
                ),
              ),
            );
            if (changed == true) vm.refresh();
          },
        );
      },
    );
  }

  Widget _buildFooter(FeaturedPlaylistsViewModel viewModel) {
    if (viewModel.isLoadingMore) {
      return const AppShimmer(child: _PlaylistCardSkeleton());
    }
    return const SizedBox(height: 120);
  }

  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedMusicNote01,
                  color: AppColors.textSecondary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No playlists available',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    FeaturedPlaylistsViewModel viewModel,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load playlists',
            style: AppTextStyles.bodySecondaryWhite.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: viewModel.retry,
            child: Text(
              'Retry',
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer skeletons ───────────────────────────────────────────────────────

class _PlaylistGridShimmer extends StatelessWidget {
  const _PlaylistGridShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const _PlaylistCardSkeleton(),
      ),
    );
  }
}

class _PlaylistCardSkeleton extends StatelessWidget {
  const _PlaylistCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              radius: 16,
            ),
          ),
          SizedBox(height: 12),
          ShimmerBox(width: 110, height: 14, radius: 6),
          SizedBox(height: 8),
          ShimmerBox(width: 72, height: 11, radius: 6),
        ],
      ),
    );
  }
}
