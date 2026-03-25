import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/discover_viewmodel.dart';
import '../widgets/section_header.dart';
import '../widgets/genre_chip.dart';
import '../widgets/playlist_card.dart';
import '../widgets/suggest_user_tile.dart';
import '../widgets/add_playlist_sheet.dart';
import 'search_screen.dart';
import 'browse_genres_screen.dart';
import 'genre_detail_screen.dart';
import 'playlist_detail_screen.dart';
import 'spotify_import_screen.dart';
import 'playlist_editor_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DiscoverViewModel(ctx.read<DiscoverRepository>()),
      child: const _DiscoverScreenContent(),
    );
  }
}

class _DiscoverScreenContent extends StatelessWidget {
  const _DiscoverScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiscoverViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (viewModel.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardFront,
        onRefresh: viewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Browse by Genre Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: AppStrings.discover.browseByGenre,
                  onSeeAll: () async {
                    final vm = context.read<DiscoverViewModel>();
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BrowseGenresScreen(),
                      ),
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

              // --- Featured Playlists Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: AppStrings.discover.featuredPlaylists,
                  onSeeAll: () {},
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

              // --- Suggest for you Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: AppStrings.discover.suggestForYou),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: viewModel.suggestedUsers.map((user) {
                    return SuggestUserTile(
                      name: user['name']!,
                      subtitle: user['subtitle']!,
                      avatarUrl: user['avatar']!,
                      onFollow: () {},
                    );
                  }).toList(),
                ),
              ),

              // Extra padding to avoid content overlapping with the sliding Nav Bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
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
