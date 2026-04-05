import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/genre_detail_viewmodel.dart';
import '../widgets/playlist_card.dart';
import 'playlist_detail_screen.dart';

class GenreDetailScreen extends StatelessWidget {
  final String genre;

  const GenreDetailScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => GenreDetailViewModel(
        genre: genre,
        repository: ctx.read<DiscoverRepository>(),
      ),
      child: _GenreDetailContent(genre: genre),
    );
  }
}

class _GenreDetailContent extends StatefulWidget {
  final String genre;

  const _GenreDetailContent({required this.genre});

  @override
  State<_GenreDetailContent> createState() => _GenreDetailContentState();
}

class _GenreDetailContentState extends State<_GenreDetailContent> {
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
      context.read<GenreDetailViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenreDetailViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: viewModel.isLoading
          ? const _PlaylistGridShimmer()
          : viewModel.error != null
          ? _buildError(context)
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardFront,
              onRefresh: viewModel.refresh,
              child: viewModel.playlists.isEmpty
                  ? _buildEmpty()
                  : _buildList(context, viewModel),
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
        widget.genre,
        style: AppTextStyles.heading3.copyWith(color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildList(BuildContext context, GenreDetailViewModel viewModel) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      // +1 for the footer (loader or bottom padding)
      itemCount: viewModel.playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == viewModel.playlists.length) {
          return _buildFooter(viewModel);
        }
        final item = viewModel.playlists[index];
        return PlaylistCard(
          title: item.title,
          subtitle: item.subtitle,
          imageUrl: item.imageUrl,
          heroTag: item.id,
          onTap: () async {
            final vm = context.read<GenreDetailViewModel>();
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PlaylistDetailScreen(playlistId: item.id, heroTag: item.id),
              ),
            );
            if (changed == true) vm.refresh();
          },
        );
      },
    );
  }

  Widget _buildFooter(GenreDetailViewModel viewModel) {
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
                  AppStrings.discover.noPlaylistsInGenre,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.discover.noPlaylistsSubtitle,
                  style: AppTextStyles.bodySecondaryWhite.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final viewModel = context.read<GenreDetailViewModel>();
    return Center(
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
          Expanded(child: ShimmerBox(width: double.infinity, radius: 16)),
          SizedBox(height: 12),
          ShimmerBox(width: 110, height: 14, radius: 6),
          SizedBox(height: 8),
          ShimmerBox(width: 72, height: 11, radius: 6),
        ],
      ),
    );
  }
}
