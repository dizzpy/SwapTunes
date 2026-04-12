import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/song_builder_model.dart';
import '../viewmodels/song_builder_viewmodel.dart';
import '../widgets/instrument_chip_row.dart';
import '../widgets/message_recipient_sheet.dart';
import '../widgets/song_structure_sheet.dart';
import 'song_builder_loading_screen.dart';

/// Overview card — Screen 1 of the Song Builder result flow.
///
/// On first load, plays a shimmer-wipe reveal: a glowing line sweeps
/// top-to-bottom, unveiling each section as it passes.
class SongBuilderResultScreen extends StatefulWidget {
  const SongBuilderResultScreen({super.key});

  @override
  State<SongBuilderResultScreen> createState() =>
      _SongBuilderResultScreenState();
}

class _SongBuilderResultScreenState extends State<SongBuilderResultScreen>
    with TickerProviderStateMixin {
  // ── Reveal animation ──
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealProgress;
  bool _revealStarted = false;

  // Per-section fade controllers (created dynamically)
  final List<AnimationController> _sectionCtrls = [];
  final List<Animation<double>> _sectionFades = [];
  final List<Animation<Offset>> _sectionSlides = [];

  // Bottom bar
  late final AnimationController _bottomCtrl;
  late final Animation<double> _bottomFade;
  late final Animation<Offset> _bottomSlide;

  // How many sections we have (set when we know the result)
  int _sectionCount = 0;

  @override
  void initState() {
    super.initState();

    // Main reveal sweep — drives the glowing line position
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _revealProgress = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeInOutCubic,
    );

    // Bottom actions bar
    _bottomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bottomFade = CurvedAnimation(
      parent: _bottomCtrl,
      curve: Curves.easeOutCubic,
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<SongBuilderViewModel>();
      if (vm.result != null && !_revealStarted) {
        _buildSectionControllers(vm.result!);
        _startReveal();
      }
    });
  }

  void _buildSectionControllers(SongBuilderResult result) {
    if (_sectionCtrls.isNotEmpty) return; // already built

    final isVocal = result.type == 'vocal';
    final hasHook = isVocal && result.sampleHook != null;

    _sectionCount = 4 + (hasHook ? 1 : 0) + 1;

    for (int i = 0; i < _sectionCount; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _sectionCtrls.add(ctrl);
      _sectionFades.add(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
      _sectionSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
      );
    }

    // Trigger rebuild so the list picks up the new controllers
    if (mounted) setState(() {});
  }

  Future<void> _startReveal() async {
    if (_revealStarted) return;
    _revealStarted = true;

    // Small pause before starting
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Start the sweep line
    _revealCtrl.forward();

    // Stagger each section as the sweep passes it
    for (int i = 0; i < _sectionCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      _sectionCtrls[i].forward();
    }

    // Bottom bar appears last
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _bottomCtrl.forward();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _bottomCtrl.dispose();
    for (final c in _sectionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Regenerate ──

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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SongBuilderLoadingScreen()));
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

  // ── Wrap a widget with its section reveal animation ──

  Widget _revealSection(int index, Widget child) {
    if (index >= _sectionFades.length) return child;
    return SlideTransition(
      position: _sectionSlides[index],
      child: FadeTransition(opacity: _sectionFades[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SongBuilderViewModel>();
    final result = vm.result;

    if (result == null) return const SizedBox.shrink();

    // Controllers not built yet — build them, reveal will start after setState
    if (_sectionCtrls.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _buildSectionControllers(result);
        _startReveal();
      });
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      );
    }

    final isVocal = result.type == 'vocal';
    final hasHook = isVocal && result.sampleHook != null;

    // Build section index mapping
    int idx = 0;

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
      body: Stack(
        children: [
          // ── Sweep glow line (animated overlay) ──
          AnimatedBuilder(
            animation: _revealProgress,
            builder: (context, _) {
              return CustomPaint(
                painter: _SweepLinePainter(
                  progress: _revealProgress.value,
                  primary: AppColors.primary,
                ),
                size: Size.infinite,
              );
            },
          ),

          // ── Content ──
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  children: [
                    // Section 0: Title
                    _revealSection(
                      idx++,
                      Text(
                        result.title,
                        style: AppTextStyles.heading2.copyWith(height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 1: Chips
                    _revealSection(idx++, _MetaChips(result: result)),
                    const SizedBox(height: 20),

                    // Section 2: Hook (optional)
                    if (hasHook) ...[
                      _revealSection(
                        idx++,
                        _HookBlock(hook: result.sampleHook!),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section N: Vibe
                    _revealSection(
                      idx++,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SmallCapsLabel(
                            label: AppStrings.songBuilder.vibeSection,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.vibe,
                            style: AppTextStyles.bodyPrimary.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section N+1: Instruments
                    _revealSection(
                      idx++,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SmallCapsLabel(
                            label: AppStrings.songBuilder.instrumentsSection,
                          ),
                          const SizedBox(height: 10),
                          InstrumentChipRow(instruments: result.instruments),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section N+2: View Structure button
                    _revealSection(
                      idx++,
                      _ViewStructureButton(
                        onTap: () => _onViewStructure(context),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom actions with reveal ──
              SlideTransition(
                position: _bottomSlide,
                child: FadeTransition(
                  opacity: _bottomFade,
                  child: _BottomActions(
                    onRegenerate: () => _onRegenerateTap(context),
                    onSend: () => _onSend(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SWEEP LINE PAINTER
// ─────────────────────────────────────────────

/// Paints a horizontal glowing green line that sweeps from top to bottom.
/// [progress] goes from 0.0 (top) to 1.0 (bottom/gone).
class _SweepLinePainter extends CustomPainter {
  final double progress;
  final Color primary;

  _SweepLinePainter({required this.progress, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final y = size.height * progress;

    // Wide soft glow behind the line
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withValues(alpha: 0.0),
          primary.withValues(alpha: 0.04),
          primary.withValues(alpha: 0.08),
          primary.withValues(alpha: 0.04),
          primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 60, size.width, 120));

    canvas.drawRect(Rect.fromLTWH(0, y - 60, size.width, 120), glowPaint);

    // Sharp line
    final linePaint = Paint()
      ..color = primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Bright center dot on the line
    final dotPaint = Paint()
      ..color = primary.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size.width / 2, y), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────
//  SAVE ICON BUTTON
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
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
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
