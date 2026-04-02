import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/collab_model.dart';
import '../viewmodels/collab_viewmodel.dart';
import '../widgets/collab_post_card.dart';
import '../widgets/dashed_create_button.dart';
import 'collab_details_screen.dart';
import 'new_collaboration_screen.dart';

/// Screen for viewing and managing the authenticated creator's collab posts.
class ManageCollaborationsScreen extends StatefulWidget {
  const ManageCollaborationsScreen({super.key});

  @override
  State<ManageCollaborationsScreen> createState() =>
      _ManageCollaborationsScreenState();
}

class _ManageCollaborationsScreenState
    extends State<ManageCollaborationsScreen> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      context.read<CollabViewmodel>().loadMyCollabs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppIconButton(
            icon: AppAssets.icon.arrowLeft,
            variant: AppIconButtonVariant.empty,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          AppStrings.collab.manageTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _InfoBanner(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: DashedCreateButton(
                onTap: () async {
                  final vm = context.read<CollabViewmodel>();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NewCollaborationScreen(),
                    ),
                  );
                  if (!mounted) return;
                  vm.loadMyCollabs();
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                AppStrings.collab.activePosts,
                style: AppTextStyles.bodyPrimary.copyWith(fontSize: 17),
              ),
            ),
          ),
          _buildContent(context, vm),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CollabViewmodel vm) {
    if (vm.isMyCollabsLoading && vm.myCollabs.isEmpty) {
      return _LoadingSliver();
    }

    if (vm.myCollabsError != null && vm.myCollabs.isEmpty) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: vm.myCollabsError!,
          onRetry: () => context.read<CollabViewmodel>().loadMyCollabs(),
        ),
      );
    }

    if (vm.myCollabs.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final collab = vm.myCollabs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CollabPostCard(
              collab: collab,
              showAuthorHeader: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CollabDetailsScreen(collabId: collab.id),
                ),
              ),
              actionsRow: _ActionsRow(collab: collab),
            ),
          );
        }, childCount: vm.myCollabs.length),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.collab.manageInfoBanner,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final CollabModel collab;

  const _ActionsRow({required this.collab});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabViewmodel>();
    final isDeleting = vm.isDeleting(collab.id);

    return Row(
      children: [
        Expanded(
          child: OutlinedAppButton(
            text: AppStrings.collab.editAction,
            height: 44,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              color: AppColors.textWhite,
              size: 18,
            ),
            onPressed: () async {
              final vm = context.read<CollabViewmodel>();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NewCollaborationScreen(existingCollab: collab),
                ),
              );
              if (!context.mounted) return;
              vm.loadMyCollabs();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Opacity(
            opacity: isDeleting ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: isDeleting,
              child: OutlinedAppButton(
                text: AppStrings.collab.deleteAction,
                height: 44,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.danger,
                        ),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.danger,
                        size: 18,
                      ),
                textColor: AppColors.danger,
                borderColor: AppColors.danger.withValues(alpha: 0.3),
                onPressed: () async {
                  final confirmed = await AppConfirmDialog.show(
                    context,
                    title: AppStrings.collab.deleteDialogTitle,
                    message: AppStrings.collab.deleteDialogBody,
                    confirmLabel: AppStrings.collab.deleteDialogConfirm,
                    cancelLabel: AppStrings.collab.deleteDialogCancel,
                    isDanger: true,
                  );
                  if (confirmed != true || !context.mounted) return;
                  final success = await context
                      .read<CollabViewmodel>()
                      .deleteCollab(collab.id);
                  if (!context.mounted) return;
                  if (success) {
                    AppSnackbar.success(AppStrings.collab.deleteSuccess);
                  } else {
                    AppSnackbar.error(AppStrings.collab.deleteError);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          childCount: 3,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.post_add_outlined,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.collab.noMyCollabs,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.collab.noMyCollabsSubtitle,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
