import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/song_builder_model.dart';
import '../viewmodels/song_builder_viewmodel.dart';
import '../widgets/instrument_chip_row.dart';
import '../widgets/message_recipient_sheet.dart';
import '../widgets/song_structure_sheet.dart';
import 'song_builder_loading_screen.dart';

/// Overview card — Screen 1 of the Song Builder result flow.
class SongBuilderResultScreen extends StatelessWidget {
  const SongBuilderResultScreen({super.key});

  // ── Regenerate: show confirmation dialog first ──
  void _onRegenerateTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardFront,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.songBuilder.regenDialogTitle,
          style: AppTextStyles.heading3,
        ),
        content: Text(
          AppStrings.songBuilder.regenDialogBody,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.songBuilder.regenDialogCancel,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doRegenerate(context);
            },
            child: Text(
              AppStrings.songBuilder.regenDialogConfirm,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doRegenerate(BuildContext context) async {
    context.read<SongBuilderViewModel>().regenerate();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SongBuilderLoadingScreen()),
    );
  }

  // ── Save ──
  void _onSave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardFront,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.songBuilder.saveDialogTitle,
          style: AppTextStyles.heading3,
        ),
        content: Text(
          AppStrings.songBuilder.saveDialogBody,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.songBuilder.saveDialogCancel,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doSave(context);
            },
            child: Text(
              AppStrings.songBuilder.saveDialogConfirm,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSave(BuildContext context) async {
    final vm = context.read<SongBuilderViewModel>();
    await vm.savePlan();
    if (!context.mounted) return;

    final saved = vm.isSaved;
    final err = vm.saveError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? AppStrings.songBuilder.saveSuccess
              : (err ?? AppStrings.songBuilder.saveError),
        ),
        backgroundColor: saved ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onViewStructure(BuildContext context) {
    final result = context.read<SongBuilderViewModel>().result;
    if (result == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongStructureSheet(result: result),
    );
  }

  void _onSend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MessageRecipientSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SongBuilderViewModel>();
    final result = vm.result;

    if (result == null) return const SizedBox.shrink();

    final isVocal = result.type == 'vocal';

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
          AppStrings.songBuilder.resultAppBarTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SaveIconButton(
              isSaving: vm.isSaving,
              isSaved: vm.isSaved,
              onTap: () => _onSave(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: [
                // ── Song title ──
                Text(
                  result.title,
                  style: AppTextStyles.heading2.copyWith(height: 1.2),
                ),
                const SizedBox(height: 14),

                // ── Metadata chips ──
                _MetaChips(result: result),
                const SizedBox(height: 20),

                // ── Hook line (vocal only) ──
                if (isVocal && result.sampleHook != null) ...[
                  _HookBlock(hook: result.sampleHook!),
                  const SizedBox(height: 20),
                ],

                // ── Vibe ──
                _SmallCapsLabel(label: AppStrings.songBuilder.vibeSection),
                const SizedBox(height: 8),
                Text(
                  result.vibe,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Instruments ──
                _SmallCapsLabel(label: AppStrings.songBuilder.instrumentsSection),
                const SizedBox(height: 10),
                InstrumentChipRow(instruments: result.instruments),
                const SizedBox(height: 12),

                // ── View Song Structure button ──
                _ViewStructureButton(
                  onTap: () => _onViewStructure(context),
                ),
              ],
            ),
          ),
          _BottomActions(
            onRegenerate: () => _onRegenerateTap(context),
            onSend: () => _onSend(context),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SAVE ICON BUTTON (AppBar action)
// ─────────────────────────────────────────────

class _SaveIconButton extends StatelessWidget {
  final bool isSaving;
  final bool isSaved;
  final VoidCallback onTap;

  const _SaveIconButton({
    required this.isSaving,
    required this.isSaved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return AppIconButton(
      icon: isSaved
          ? HugeIcons.strokeRoundedCheckmarkCircle01
          : HugeIcons.strokeRoundedFolderAdd,
      onTap: isSaved ? () {} : onTap,
      variant: AppIconButtonVariant.filled,
    );
  }
}

// ─────────────────────────────────────────────
//  METADATA CHIPS
// ─────────────────────────────────────────────

class _MetaChips extends StatelessWidget {
  final SongBuilderResult result;

  const _MetaChips({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: result.genre),
        const SizedBox(width: 8),
        _Chip(label: '${result.bpm} BPM'),
        const SizedBox(width: 8),
        _Chip(label: result.key),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOOK BLOCK
// ─────────────────────────────────────────────

class _HookBlock extends StatelessWidget {
  final String hook;

  const _HookBlock({required this.hook});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Text(
        '"$hook"',
        style: AppTextStyles.bodyPrimary.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.6,
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL CAPS LABEL
// ─────────────────────────────────────────────

class _SmallCapsLabel extends StatelessWidget {
  final String label;

  const _SmallCapsLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.bodySecondary.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VIEW STRUCTURE BUTTON
// ─────────────────────────────────────────────

class _ViewStructureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewStructureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.songBuilder.viewStructureButton,
              style: AppTextStyles.bodyPrimary.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM ACTIONS
// ─────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final VoidCallback onRegenerate;
  final VoidCallback onSend;

  const _BottomActions({required this.onRegenerate, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedAppButton(
              text: AppStrings.songBuilder.regenerateButton,
              height: 52,
              onPressed: onRegenerate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GreenButton(
              text: AppStrings.songBuilder.sendButton,
              height: 52,
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
