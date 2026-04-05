import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../feed/presentation/screens/main_layout_screen.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/suggested_user_model.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/recent_search_tile.dart';
import '../widgets/suggest_user_tile.dart';
import '../widgets/trending_tag_chip.dart';
import 'playlist_detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SearchViewModel(
        ctx.read<DiscoverRepository>(),
        ctx.read<ProfileRepository>(),
        ctx.read<StorageService>(),
      ),
      child: const _SearchScreenContent(),
    );
  }
}

class _SearchScreenContent extends StatefulWidget {
  const _SearchScreenContent();

  @override
  State<_SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<_SearchScreenContent> {
  @override
  void initState() {
    super.initState();
    MainLayoutScreen.hideNavBar();
  }

  @override
  void dispose() {
    MainLayoutScreen.showNavBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header area (back + search bar + tabs) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardFront,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: HugeIcon(
                        icon: AppAssets.icon.arrowLeft,
                        color: AppColors.textWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search input
                  AppSearchBar(
                    controller: viewModel.searchController,
                    hintText: 'Search users, playlists...',
                    onChanged: (_) {},
                    onClear: viewModel.clearSearch,
                  ),
                  const SizedBox(height: 20),

                  // Tabs
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.tabs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 32),
                      itemBuilder: (context, index) {
                        final tab = viewModel.tabs[index];
                        final isActive = tab == viewModel.activeTab;
                        return GestureDetector(
                          onTap: () => viewModel.setTab(tab),
                          child: Text(
                            tab,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // --- Scrollable body ---
            Expanded(
              child: viewModel.hasQuery
                  ? _buildResults(context, viewModel)
                  : _buildEmptyState(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results view ──────────────────────────────────────────

  Widget _buildResults(BuildContext context, SearchViewModel viewModel) {
    if (viewModel.isSearching) {
      return const _SearchShimmer();
    }

    if (viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Something went wrong. Please try again.',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!viewModel.hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: AppAssets.icon.search,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different keyword',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Users section
        if (viewModel.userResults.isNotEmpty) ...[
          _SectionLabel(
            label: 'Users',
            count: viewModel.userResults.length,
          ),
          const SizedBox(height: 12),
          ...viewModel.userResults.map(
            (user) => _buildUserTile(context, viewModel, user),
          ),
          const SizedBox(height: 24),
        ],

        // Playlists section
        if (viewModel.playlistResults.isNotEmpty) ...[
          _SectionLabel(
            label: 'Playlists',
            count: viewModel.playlistResults.length,
          ),
          const SizedBox(height: 12),
          ...viewModel.playlistResults.map(
            (playlist) => _buildPlaylistTile(context, playlist),
          ),
          const SizedBox(height: 24),
        ],

        // Creators section
        if (viewModel.creatorResults.isNotEmpty) ...[
          _SectionLabel(
            label: 'Creators',
            count: viewModel.creatorResults.length,
          ),
          const SizedBox(height: 12),
          ...viewModel.creatorResults.map(
            (creator) => _buildUserTile(context, viewModel, creator),
          ),
        ],
      ],
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    SearchViewModel viewModel,
    SuggestedUserModel user,
  ) {
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
          builder: (_) => UserProfileScreen(username: user.username),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(BuildContext context, PlaylistModel playlist) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(
            playlistId: playlist.id,
            heroTag: 'search_${playlist.id}',
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: playlist.coverImageUrl != null
                    ? Image.network(
                        playlist.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _playlistFallback(),
                      )
                    : _playlistFallback(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: AppTextStyles.bodyPrimary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.genreTags.isNotEmpty
                        ? playlist.genreTags.join(', ')
                        : '@${playlist.ownerUsername}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${playlist.trackCount} tracks',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(
                      icon: AppAssets.icon.favoriteOutline,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${playlist.likesCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistFallback() {
    return Container(
      color: AppColors.skeletonHighlight,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  // ── Empty state (no query) ────────────────────────────────

  Widget _buildEmptyState(BuildContext context, SearchViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Search', style: AppTextStyles.heading3),
              if (viewModel.recentSearches.isNotEmpty)
                GestureDetector(
                  onTap: viewModel.clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (viewModel.recentSearches.isNotEmpty)
            Column(
              children: List.generate(viewModel.recentSearches.length, (index) {
                final query = viewModel.recentSearches[index];
                return RecentSearchTile(
                  title: query,
                  subtitle: 'Recent search',
                  onRemove: () => viewModel.removeRecentSearch(index),
                );
              }),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent searches',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Trending section
          const Text('Trending', style: AppTextStyles.heading3),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: viewModel.trendingTags.map((tag) {
              return GestureDetector(
                onTap: () {
                  viewModel.searchController.text = tag;
                  viewModel.searchController.selection =
                      TextSelection.fromPosition(
                    TextPosition(
                      offset: viewModel.searchController.text.length,
                    ),
                  );
                },
                child: TrendingTagChip(label: tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;

  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.heading3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const ShimmerBox(width: 60, height: 14, radius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardFront,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  ShimmerCircle(size: 48),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14, radius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(width: 80, height: 11, radius: 6),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  ShimmerBox(width: 70, height: 32, radius: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerBox(width: 80, height: 14, radius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardFront,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 48, height: 48, radius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 150, height: 14, radius: 6),
                        SizedBox(height: 6),
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
    );
  }
}
