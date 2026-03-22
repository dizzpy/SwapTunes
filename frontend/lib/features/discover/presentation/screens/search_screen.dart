import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/recent_search_tile.dart';
import '../widgets/trending_tag_chip.dart';
import '../../../../core/widgets/app_search_bar.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _SearchScreenContent(),
    );
  }
}

class _SearchScreenContent extends StatelessWidget {
  const _SearchScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header / Back Button ---
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

              // --- Search Input Field ---
              AppSearchBar(
                hintText: 'Search user, playlists...',
                onClear: () {
                  // Clear logic would go here
                },
              ),
              const SizedBox(height: 24),

              // --- Tabs ---
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 32),
                  itemBuilder: (context, index) {
                    final tab = viewModel.tabs[index];
                    final isActive = tab == viewModel.activeTab;

                    return GestureDetector(
                      onTap: () => viewModel.setTab(tab),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
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
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            // Optional indicator underneath if desired:
                            // Container(height: 2, width: 20, color: AppColors.primary),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // --- Recent Search Section ---
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

              // Recent Searches List
              if (viewModel.recentSearches.isNotEmpty)
                Column(
                  children: List.generate(viewModel.recentSearches.length, (
                    index,
                  ) {
                    final item = viewModel.recentSearches[index];
                    return RecentSearchTile(
                      title: item['title']!,
                      subtitle: item['subtitle']!,
                      onRemove: () => viewModel.removeRecentSearch(index),
                    );
                  }),
                ),
              const SizedBox(height: 16),

              // --- Trending Section ---
              const Text('Trending', style: AppTextStyles.heading3),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: viewModel.trendingTags.map((tag) {
                  return TrendingTagChip(label: tag);
                }).toList(),
              ),

              // Bottom padding
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
