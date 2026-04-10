import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../viewmodels/collab_match_viewmodel.dart';
import '../widgets/match_card.dart';
import '../widgets/match_card_shimmer.dart';

/// Displays AI-matched creators for a collab listing.
class CollabMatchScreen extends StatefulWidget {
  final String collabId;
  final String collabTitle;

  const CollabMatchScreen({
    super.key,
    required this.collabId,
    required this.collabTitle,
  });

  @override
  State<CollabMatchScreen> createState() => _CollabMatchScreenState();
}

class _CollabMatchScreenState extends State<CollabMatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CollabMatchViewModel>();
      // Only fetch if not already loaded — avoids re-fetching when arriving
      // from CollabMatchLoadingScreen which has already completed the call.
      if (vm.state == CollabMatchState.idle) {
        vm.fetchMatches(widget.collabId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabMatchViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppIconButton(
              icon: AppAssets.icon.arrowLeft,
              onTap: () => Navigator.pop(context),
              variant: AppIconButtonVariant.filled,
            ),
          ),
        ),
        title: Text(
          AppStrings.collab.matchScreenTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, CollabMatchViewModel vm) {
    if (vm.state == CollabMatchState.loading) {
      return _LoadingState();
    }

    if (vm.state == CollabMatchState.error) {
      return _ErrorState(
        message: vm.errorMessage ?? AppStrings.collab.matchError,
        onRetry: () => context
            .read<CollabMatchViewModel>()
            .fetchMatches(widget.collabId),
      );
    }

    if (vm.state == CollabMatchState.loaded && vm.matches.isEmpty) {
      return _EmptyState();
    }

    if (vm.state == CollabMatchState.loaded) {
      return _MatchList(
        matches: vm.matches.map((m) => MatchCard(match: m)).toList(),
        matchCount: vm.matches.length,
        collabTitle: widget.collabTitle,
      );
    }

    return const SizedBox.shrink();
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: const [
        MatchCardShimmer(),
        SizedBox(height: 16),
        MatchCardShimmer(),
        SizedBox(height: 16),
        MatchCardShimmer(),
      ],
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<Widget> matches;
  final int matchCount;
  final String collabTitle;

  const _MatchList({
    required this.matches,
    required this.matchCount,
    required this.collabTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _Header(matchCount: matchCount, collabTitle: collabTitle),
        const SizedBox(height: 20),
        ...matches.expand((card) => [card, const SizedBox(height: 16)]),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int matchCount;
  final String collabTitle;

  const _Header({required this.matchCount, required this.collabTitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.collab.matchSubtitle,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedMusicNote01,
                color: AppColors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  collabTitle,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedUserSearch01,
              color: AppColors.textSecondary,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.collab.noMatchesFound,
              style: AppTextStyles.bodyPrimary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.collab.noMatchesSubtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
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
    );
  }
}
