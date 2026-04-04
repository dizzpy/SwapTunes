import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/discover_viewmodel.dart';
import '../widgets/section_header.dart';
import '../widgets/genre_chip.dart';
import '../widgets/playlist_card.dart';
import '../widgets/suggest_user_tile.dart';
import '../widgets/add_playlist_sheet.dart';
import 'featured_playlists_screen.dart';
import 'search_screen.dart';
import 'browse_genres_screen.dart';
import 'suggested_users_screen.dart';
import 'genre_detail_screen.dart';
import 'playlist_detail_screen.dart';
import 'spotify_import_screen.dart';
import 'playlist_editor_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DiscoverViewModel(
        ctx.read<DiscoverRepository>(),
        ctx.read<ProfileRepository>(),
      ),
      child: const _DiscoverScreenContent(),
    );
  }
}

class _DiscoverScreenContent extends StatelessWidget {
  const _DiscoverScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiscoverViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardFront,
        onRefresh: viewModel.isLoading ? () async {} : viewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: viewModel.isLoading
              ? const _DiscoverShimmer()
              : viewModel.error != null
                  ? _buildError(context, viewModel)
                  : _buildContent(context, viewModel),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, DiscoverViewModel viewModel) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
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

  Widget _buildContent(BuildContext context, DiscoverViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Browse by Genre ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(
            title: AppStrings.discover.browseByGenre,
            onSeeAll: () async {
              final vm = context.read<DiscoverViewModel>();
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const BrowseGenresScreen()),
              );
              if (changed == true) vm.refresh();
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.genres.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final genre = viewModel.genres[index];
              return GenreChip(
                label: genre,
                onTap: () async {
                  final vm = context.read<DiscoverViewModel>();
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GenreDetailScreen(genre: genre),
                    ),
                  );
                  if (changed == true) vm.refresh();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 32),

        // --- Featured Playlists ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(
            title: AppStrings.discover.featuredPlaylists,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeaturedPlaylistsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.playlists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final playlist = viewModel.playlists[index];
              return PlaylistCard(
                title: playlist.name,
                subtitle: playlist.genreTags.isNotEmpty
                    ? playlist.genreTags.join(', ')
                    : playlist.ownerUsername,
                imageUrl: playlist.coverImageUrl,
                heroTag: playlist.id,
                onTap: () async {
                  final vm = context.read<DiscoverViewModel>();
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
          ),
        ),
        const SizedBox(height: 32),

        // --- Suggested for you ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(
            title: AppStrings.discover.suggestForYou,
            onSeeAll: viewModel.suggestedUsers.length > 3
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SuggestedUsersScreen(viewModel: viewModel),
                      ),
                    )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: viewModel.suggestedUsers.take(3).map((user) {
              return SuggestUserTile(
                name: user.fullName,
                subtitle: user.userType ?? '@${user.username}',
                avatarUrl: user.avatarUrl,
                isFollowing: viewModel.isFollowing(user.id),
                isLoading: viewModel.isFollowLoading(user.id),
                onFollow: () => viewModel.toggleFollow(user.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserProfileScreen(username: user.username),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 120),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        _buildIconAction(
          AppAssets.icon.add,
          () => AddPlaylistSheet.show(
            context,
            onImportFromSpotify: () async {
              final vm = context.read<DiscoverViewModel>();
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SpotifyImportScreen()),
              );
              if (changed == true) vm.refresh();
            },
            onCreateManually: () async {
              final vm = context.read<DiscoverViewModel>();
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistEditorScreen()),
              );
              if (changed == true) vm.refresh();
            },
          ),
        ),
        const SizedBox(width: 12),
        _buildIconAction(AppAssets.icon.search, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        }),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildIconAction(dynamic icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: IconButton(
        icon: icon is IconData
            ? Icon(icon, color: AppColors.textWhite, size: 22)
            : HugeIcon(icon: icon, color: AppColors.textWhite, size: 22),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

// ── Shimmer skeleton ────────────────────────────────────────────────────────

class _DiscoverShimmer extends StatelessWidget {
  const _DiscoverShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Genre chips skeleton ---
          _skeletonSectionHeader(),
          const SizedBox(height: 16),
          _genreChipsSkeleton(),
          const SizedBox(height: 32),

          // --- Playlist cards skeleton ---
          _skeletonSectionHeader(),
          const SizedBox(height: 16),
          _playlistCardsSkeleton(),
          const SizedBox(height: 32),

          // --- User tiles skeleton ---
          _skeletonSectionHeader(),
          const SizedBox(height: 16),
          _userTilesSkeleton(),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // "Title ——————————  See All" placeholder
  Widget _skeletonSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const ShimmerBox(width: 130, height: 18, radius: 8),
          const ShimmerBox(width: 52, height: 14, radius: 6),
        ],
      ),
    );
  }

  // Horizontal row of genre chip placeholders
  Widget _genreChipsSkeleton() {
    const widths = [72.0, 88.0, 64.0, 96.0, 76.0];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ShimmerBox(width: widths[i], height: 40, radius: 20),
      ),
    );
  }

  // Horizontal row of playlist card placeholders (matches 240×310 card size)
  Widget _playlistCardsSkeleton() {
    return SizedBox(
      height: 310,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image placeholder
              const Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  radius: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Title line
              const ShimmerBox(width: 160, height: 16, radius: 6),
              const SizedBox(height: 8),
              // Subtitle line
              const ShimmerBox(width: 100, height: 12, radius: 6),
            ],
          ),
        ),
      ),
    );
  }

  // Vertical stack of user tile placeholders (matches SuggestUserTile)
  Widget _userTilesSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (_) => _userTileSkeleton()),
      ),
    );
  }

  Widget _userTileSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const ShimmerCircle(size: 52),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 11, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(width: 80, height: 36, radius: 24),
        ],
      ),
    );
  }
}
