import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_icon_button.dart';
import '../viewmodels/collab_match_viewmodel.dart';
import '../widgets/match_card.dart';
import '../widgets/match_card_shimmer.dart';

/// Displays AI-matched creators for a collab listing.
///
/// On first load, plays a shimmer-wipe reveal: a glowing line sweeps
/// top-to-bottom, unveiling each section as it passes.
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

class _CollabMatchScreenState extends State<CollabMatchScreen>
    with TickerProviderStateMixin {
  bool _revealStarted = false;

  // Sweep line
  late final AnimationController _sweepCtrl;
  late final Animation<double> _sweepProgress;

  // Per-section animations (header + each card)
  final List<AnimationController> _sectionCtrls = [];
  final List<Animation<double>> _sectionFades = [];
  final List<Animation<Offset>> _sectionSlides = [];

  @override
  void initState() {
    super.initState();

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _sweepProgress = CurvedAnimation(
      parent: _sweepCtrl,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CollabMatchViewModel>();

      if (vm.state == CollabMatchState.idle) {
        vm.fetchMatches(widget.collabId);
      } else if (vm.state == CollabMatchState.loaded) {
        _buildSectionControllers(vm.matches.length);
        _startReveal();
      }
    });
  }

  void _buildSectionControllers(int cardCount) {
    if (_sectionCtrls.isNotEmpty) return;

    // Section 0 = header, then one per card
    final total = 1 + cardCount;

    for (int i = 0; i < total; i++) {
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

    if (mounted) setState(() {});
  }

  Future<void> _startReveal() async {
    if (_revealStarted) return;
    _revealStarted = true;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _sweepCtrl.forward();

    // Stagger each section as the sweep passes
    for (int i = 0; i < _sectionCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _sectionCtrls[i].forward();
    }
  }

  Widget _revealSection(int index, Widget child) {
    if (index >= _sectionFades.length) return child;
    return SlideTransition(
      position: _sectionSlides[index],
      child: FadeTransition(opacity: _sectionFades[index], child: child),
    );
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    for (final c in _sectionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabMatchViewModel>();

    // Build controllers when data arrives
    if (vm.state == CollabMatchState.loaded &&
        vm.matches.isNotEmpty &&
        _sectionCtrls.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _buildSectionControllers(vm.matches.length);
        _startReveal();
      });
    }

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
        onRetry: () =>
            context.read<CollabMatchViewModel>().fetchMatches(widget.collabId),
      );
    }

    if (vm.state == CollabMatchState.loaded && vm.matches.isEmpty) {
      return _EmptyState();
    }

    if (vm.state == CollabMatchState.loaded && _sectionCtrls.isNotEmpty) {
      return _buildRevealList(vm);
    }

    return const SizedBox.shrink();
  }

  Widget _buildRevealList(CollabMatchViewModel vm) {
    final cards = vm.matches
        .map((m) => MatchCard(match: m, collabTitle: widget.collabTitle))
        .toList();

    return Stack(
      children: [
        // ── Content (behind) ──
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _revealSection(
              0,
              _Header(
                matchCount: vm.matches.length,
                collabTitle: widget.collabTitle,
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < cards.length; i++) ...[
              _revealSection(i + 1, cards[i]),
              if (i < cards.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),

        // ── Sweep glow line (on top, ignores touches) ──
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _sweepProgress,
            builder: (context, _) {
              return CustomPaint(
                painter: _SweepLinePainter(
                  progress: _sweepProgress.value,
                  primary: AppColors.primary,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SWEEP LINE PAINTER
// ─────────────────────────────────────────────

class _SweepLinePainter extends CustomPainter {
  final double progress;
  final Color primary;

  _SweepLinePainter({required this.progress, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final y = size.height * progress;

    // Wide soft glow
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

    // Bright center dot
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
//  LOADING / SHIMMER
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int matchCount;
  final String collabTitle;

  const _Header({required this.matchCount, required this.collabTitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAiMagic,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'AI found ',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: '$matchCount creators',
                            style: AppTextStyles.bodyPrimary.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: ' for your collab',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      collabTitle,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _AiFeedbackRow(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  AI FEEDBACK ROW (UI only)
// ─────────────────────────────────────────────

class _AiFeedbackRow extends StatefulWidget {
  const _AiFeedbackRow();

  @override
  State<_AiFeedbackRow> createState() => _AiFeedbackRowState();
}

class _AiFeedbackRowState extends State<_AiFeedbackRow> {
  bool _submitted = false;
  bool _hidden = false;

  void _onFeedback() {
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hidden = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _hidden
          ? const SizedBox.shrink(key: ValueKey('hidden'))
          : _submitted
          ? Text(
              'Thanks for your feedback!',
              key: const ValueKey('thanks'),
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            )
          : Row(
              key: const ValueKey('buttons'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'How are these matches?',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                _FeedbackButton(
                  icon: HugeIcons.strokeRoundedThumbsUp,
                  onTap: _onFeedback,
                ),
                const SizedBox(width: 4),
                _FeedbackButton(
                  icon: HugeIcons.strokeRoundedThumbsDown,
                  onTap: _onFeedback,
                ),
              ],
            ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _FeedbackButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: HugeIcon(
          icon: icon,
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          size: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────

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
