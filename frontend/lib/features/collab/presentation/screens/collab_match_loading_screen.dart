import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../viewmodels/collab_match_viewmodel.dart';
import 'collab_match_screen.dart';

/// Intermediate loading screen shown while AI fetches creator matches.
///
/// Starts the fetch on init and automatically replaces itself with
/// [CollabMatchScreen] when results are ready. On error, shows a retry UI.
class CollabMatchLoadingScreen extends StatefulWidget {
  final String collabId;
  final String collabTitle;

  const CollabMatchLoadingScreen({
    super.key,
    required this.collabId,
    required this.collabTitle,
  });

  @override
  State<CollabMatchLoadingScreen> createState() =>
      _CollabMatchLoadingScreenState();
}

class _CollabMatchLoadingScreenState extends State<CollabMatchLoadingScreen> {
  late final CollabMatchViewModel _vm;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<CollabMatchViewModel>();
    _vm.addListener(_onVmChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.fetchMatches(widget.collabId);
    });
  }

  void _onVmChange() {
    if (!mounted || _hasNavigated) return;
    if (_vm.state == CollabMatchState.loaded) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollabMatchScreen(
              collabId: widget.collabId,
              collabTitle: widget.collabTitle,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    super.dispose();
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
      ),
      body: vm.state == CollabMatchState.error
          ? _ErrorState(
              message: vm.errorMessage ?? AppStrings.collab.matchError,
              onRetry: () {
                _hasNavigated = false;
                _vm.fetchMatches(widget.collabId);
              },
            )
          : const _LoadingContent(),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserSearch01,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              'Finding your matches...',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'AI is scanning creator profiles.\nThis usually takes a few seconds.',
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
          const SizedBox(height: 24),
          GreenButton(
            text: AppStrings.collab.retry,
            height: 52,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
