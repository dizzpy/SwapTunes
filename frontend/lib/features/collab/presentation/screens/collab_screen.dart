import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../ai/song_builder/presentation/screens/song_builder_input_screen.dart';
import '../viewmodels/collab_viewmodel.dart';
import '../widgets/collab_post_card.dart';
import '../widgets/tag_chip.dart';
import 'collab_details_screen.dart';
import 'manage_collaborations_screen.dart';

/// Main collaborations feed screen with filtering and pagination.
class CollabScreen extends StatefulWidget {
  const CollabScreen({super.key});

  @override
  State<CollabScreen> createState() => _CollabScreenState();
}

class _CollabScreenState extends State<CollabScreen> {
  final _scrollController = ScrollController();
  bool _fetched = false;

  static const List<String> _filters = [
    'All',
    'Vocalist',
    'Producer',
    'Mixing',
    'Mastering',
    'Songwriter',
    'Instrumentalist',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CollabViewmodel>().loadCollabs();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels != 0) {
      final vm = context.read<CollabViewmodel>();
      if (!vm.isLoadingMore && vm.hasMore) {
        vm.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.collab.screenTitle,
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppIconButton(
              icon: AppAssets.icon.add,
              variant: AppIconButtonVariant.filled,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageCollaborationsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SongBuilderBanner(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const SongBuilderInputScreen(),
              ),
            ),
          ),
          _FilterBar(
            filters: _filters,
            selected: vm.selectedFilter ?? AppStrings.collab.filterAll,
            onSelect: (f) => context.read<CollabViewmodel>().setFilter(
              f == AppStrings.collab.filterAll ? null : f,
            ),
          ),
          Expanded(
            child: _Body(vm: vm, scrollController: _scrollController),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: filters.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TagChip(
              label: f,
              isSelected: selected == f,
              onTap: () => onSelect(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final CollabViewmodel vm;
  final ScrollController scrollController;

  const _Body({required this.vm, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.collabs.isEmpty) {
      return const _LoadingShimmer();
    }

    if (vm.error != null && vm.collabs.isEmpty) {
      return _ErrorState(
        message: vm.error!,
        onRetry: () => context.read<CollabViewmodel>().loadCollabs(),
      );
    }

    if (vm.collabs.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: vm.collabs.length + (vm.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        if (i == vm.collabs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }
        final collab = vm.collabs[i];
        return CollabPostCard(
          collab: collab,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CollabDetailsScreen(collabId: collab.id),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: Text(
                AppStrings.collab.retry,
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

// ─────────────────────────────────────────────
//  SONG CONCEPT BANNER
// ─────────────────────────────────────────────

class _SongBuilderBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SongBuilderBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAiMagic,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.songBuilder.entryButtonLabel,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Generate a full song concept with AI',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.collab.noCollabsFound,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.collab.noCollabsSubtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
