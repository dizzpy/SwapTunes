import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/browse_genres_viewmodel.dart';
import '../widgets/genre_card.dart';
import 'genre_detail_screen.dart';

class BrowseGenresScreen extends StatelessWidget {
  const BrowseGenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => BrowseGenresViewModel(ctx.read<DiscoverRepository>()),
      child: const _BrowseGenresContent(),
    );
  }
}

class _BrowseGenresContent extends StatelessWidget {
  const _BrowseGenresContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BrowseGenresViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: viewModel.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : viewModel.error != null
          ? _buildError(context)
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardFront,
              onRefresh: viewModel.refresh,
              child: _buildGrid(context, viewModel),
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
        AppStrings.discover.browseGenresTitle,
        style: AppTextStyles.heading3.copyWith(color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, BrowseGenresViewModel viewModel) {
    final genres = viewModel.visibleGenres;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final genre = genres[index];
              final accentColor =
                  AppColors.genreAccents[index % AppColors.genreAccents.length];
              return GenreCard(
                label: genre,
                accentColor: accentColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GenreDetailScreen(genre: genre),
                    ),
                  );
                },
              );
            }, childCount: genres.length),
          ),
        ),

        // Load more / bottom padding
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: viewModel.hasMore
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: viewModel.loadMore,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppStrings.discover.loadMore,
                        style: AppTextStyles.bodySecondaryWhite.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final viewModel = context.read<BrowseGenresViewModel>();
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
