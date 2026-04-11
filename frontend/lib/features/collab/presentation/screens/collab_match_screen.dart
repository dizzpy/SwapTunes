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
///
/// When arriving from the loading screen with results already loaded,
/// cards reveal one-by-one with a staggered slide+fade animation
/// to give an "AI just generated this" feel.
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
  bool _controllersReady = false;

  // Header animation
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Per-card animations
  final List<AnimationController> _cardCtrls = [];
  final List<Animation<double>> _cardFades = [];
  final List<Animation<Offset>> _cardSlides = [];

  @override
  void initState() {
    super.initState();

    // Header controller — always created
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutCubic,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CollabMatchViewModel>();

      if (vm.state == CollabMatchState.idle) {
        // Arrived directly — need to fetch
        vm.fetchMatches(widget.collabId);
      } else if (vm.state == CollabMatchState.loaded) {
        // Arrived from loading screen — data ready, build controllers & animate
        _buildCardControllers(vm.matches.length);
        _runReveal();
      }
    });
  }

  /// Creates animation controllers for each card. Must be called
  /// before building the animated list.
  void _buildCardControllers(int count) {
    if (_controllersReady) return;

    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      );
      _cardCtrls.add(ctrl);
      _cardFades.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
      _cardSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
      );
    }

    _controllersReady = true;

    // Rebuild so the list picks up the new controllers
    if (mounted) setState(() {});
  }

  /// Fires the staggered reveal: header first, then cards one by one.
  Future<void> _runReveal() async {
    if (_revealStarted) return;
    _revealStarted = true;

    // Small pause so the screen settles
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _headerCtrl.forward();

    // Cards stagger in
    for (int i = 0; i < _cardCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _cardCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabMatchViewModel>();

    // If data just arrived and controllers aren't built yet, build them
    if (vm.state == CollabMatchState.loaded &&
        vm.matches.isNotEmpty &&
        !_controllersReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildCardControllers(vm.matches.length);
        _runReveal();
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

    if (vm.state == CollabMatchState.loaded && _controllersReady) {
      return _buildAnimatedList(vm);
    }

    // Controllers not ready yet — show nothing briefly
    // (will rebuild once _buildCardControllers calls setState)
    return const SizedBox.shrink();
  }

  Widget _buildAnimatedList(CollabMatchViewModel vm) {
    final cards = vm.matches
        .map((m) => MatchCard(match: m, collabTitle: widget.collabTitle))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // ── Header: slides up + fades in ──
        SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: _Header(
              matchCount: vm.matches.length,
              collabTitle: widget.collabTitle,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Cards: each one slides up + fades in with staggered delay ──
        for (int i = 0; i < cards.length; i++) ...[
          SlideTransition(
            position: _cardSlides[i],
            child: FadeTransition(opacity: _cardFades[i], child: cards[i]),
          ),
          if (i < cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
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
        // ── Single centered chip: AI badge + count + collab title ──
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
              // AI sparkle icon
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

              // Text block
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

        // ── Feedback row: "Was this helpful?" + thumbs up/down ──
        const _AiFeedbackRow(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  AI FEEDBACK ROW (UI only — no logic)
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
                  isSelected: false,
                  onTap: _onFeedback,
                ),
                const SizedBox(width: 4),
                _FeedbackButton(
                  icon: HugeIcons.strokeRoundedThumbsDown,
                  isSelected: false,
                  onTap: _onFeedback,
                ),
              ],
            ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(
          icon: icon,
          color: isSelected
              ? AppColors.primary
              : AppColors.textSecondary.withValues(alpha: 0.4),
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
