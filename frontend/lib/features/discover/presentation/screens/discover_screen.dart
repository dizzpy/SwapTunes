import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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
      create: (_) => DiscoverViewModel(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Browse by Genre Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: AppStrings.discover.browseByGenre,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BrowseGenresScreen(),
                    ),
                  );
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenreDetailScreen(genre: genre),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // --- Future Playlists Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: AppStrings.discover.futurePlaylists,
                onSeeAll: () {},
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 310,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.futurePlaylists.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final playlist = viewModel.futurePlaylists[index];
                  final tag = playlist['id'] ?? 'discover-$index';
                  return PlaylistCard(
                    title: playlist['title']!,
                    subtitle: playlist['subtitle']!,
                    imageUrl: playlist['image'],
                    heroTag: tag,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(
                            playlistId: tag,
                            heroTag: tag,
                          ),
                        ),
                      );
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
            onImportFromSpotify: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpotifyImportScreen()),
              );
            },
            onCreateManually: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistEditorScreen()),
              );
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
