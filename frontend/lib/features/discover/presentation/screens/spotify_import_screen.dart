import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../features/auth/presentation/screens/connect_spotify_screen.dart'
    show ConnectSpotifyContext, ConnectSpotifyScreen;
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/source_platform.dart';
import '../../data/models/spotify_playlist_model.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/spotify_import_viewmodel.dart';
import 'playlist_editor_screen.dart';

const _spotifyGreen = Color(0xFF1DB954);

class SpotifyImportScreen extends StatelessWidget {
  const SpotifyImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SpotifyImportViewModel(
        isSpotifyConnected:
            ctx.read<AuthViewmodel>().currentUser?.spotifyConnected ?? false,
        repository: ctx.read<DiscoverRepository>(),
      ),
      child: const _SpotifyImportContent(),
    );
  }
}

class _SpotifyImportContent extends StatelessWidget {
  const _SpotifyImportContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SpotifyImportViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: viewModel.isSpotifyConnected
          ? viewModel.isLoading
                ? const _SpotifyPlaylistsShimmer()
                : viewModel.error != null && viewModel.playlists.isEmpty
                ? _buildLoadError(context, viewModel)
                : _buildPlaylistList(context, viewModel)
          : _buildConnectPrompt(context, viewModel),
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
        AppStrings.discover.spotifyImportTitle,
        style: AppTextStyles.heading3.copyWith(color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildConnectPrompt(
    BuildContext context,
    SpotifyImportViewModel viewModel,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _spotifyGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSpotify,
                  color: _spotifyGreen,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.discover.connectSpotifyPrompt,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  AppHaptics.buttonTap();
                  final connected = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectSpotifyScreen(
                        flowContext: ConnectSpotifyContext.discover,
                      ),
                    ),
                  );
                  if (connected == true && context.mounted) {
                    context.read<SpotifyImportViewModel>().markConnected();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _spotifyGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.discover.connectSpotifyBtn,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(
    BuildContext context,
    SpotifyImportViewModel viewModel,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.discover.loadingError,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => viewModel.retry(),
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

  Widget _buildPlaylistList(
    BuildContext context,
    SpotifyImportViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            AppStrings.discover.yourSpotifyPlaylists,
            style: AppTextStyles.bodyPrimary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            itemCount: viewModel.playlists.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = viewModel.playlists[index];
              final isThisImporting =
                  viewModel.isImporting && viewModel.importingId == item.id;

              return _SpotifyPlaylistTile(
                item: item,
                isImporting: isThisImporting,
                onImport: () async {
                  AppHaptics.buttonTap();
                  final success = await viewModel.importPlaylist(item.id);
                  if (!context.mounted) return;
                  if (success) {
                    final published = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistEditorScreen(
                          initialPlatform: SourcePlatform.spotify,
                          initialPrimaryUrl: viewModel.lastImportedSpotifyUrl,
                          suggestedGenres: viewModel.lastSuggestedGenres,
                          suggestedArtists: viewModel.lastSuggestedArtists,
                        ),
                      ),
                    );
                    if (published == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } else {
                    AppSnackbar.error(AppStrings.discover.importError);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpotifyPlaylistTile extends StatelessWidget {
  final SpotifyPlaylistModel item;
  final bool isImporting;
  final VoidCallback onImport;

  const _SpotifyPlaylistTile({
    required this.item,
    required this.isImporting,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.coverImageUrl != null
                ? Image.network(
                    item.coverImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImageFallback(),
                  )
                : _buildImageFallback(),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.trackCount} ${AppStrings.discover.tracksCount}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action button
          if (item.isImported)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.discover.alreadyImported,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isImporting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _spotifyGreen,
              ),
            )
          else
            GestureDetector(
              onTap: onImport,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _spotifyGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _spotifyGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  AppStrings.discover.importBtn,
                  style: AppTextStyles.caption.copyWith(
                    color: _spotifyGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.skeletonHighlight,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}

class _SpotifyPlaylistsShimmer extends StatelessWidget {
  const _SpotifyPlaylistsShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 56, height: 56, radius: 10),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 14, radius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 11, radius: 6),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ShimmerBox(width: 60, height: 30, radius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
