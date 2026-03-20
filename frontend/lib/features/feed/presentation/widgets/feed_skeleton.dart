import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer engine
// ─────────────────────────────────────────────────────────────────────────────

/// Drives a single shimmer animation that all child skeleton boxes share.
///
/// By exposing the [linearGradient] via [ShimmerState], every [_SkeletonBox]
/// inside the same [_Shimmer] sweeps in perfect unison — the same way the
/// popular `shimmer` pub.dev package works, but inline so we can tint with
/// the app's primary green.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();

  static _ShimmerState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ShimmerState>();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Base & highlight colours
  static const _base = Color(0xFF222627);
  static const _highlight = Color(0xFF2F3535);
  static const _peak = Color(0xFF353D3B); // very subtle green-grey tint

  LinearGradient get gradient => LinearGradient(
    colors: const [_base, _highlight, _peak, _highlight, _base],
    stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
    begin: const Alignment(-2.5, -0.3),
    end: const Alignment(2.5, 0.3),
    transform: _SlideGradient(_controller.value),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SlideGradient extends GradientTransform {
  final double progress;
  const _SlideGradient(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * 2 * (progress - 0.5), 0, 0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton box
// ─────────────────────────────────────────────────────────────────────────────

/// A single shimmer-painted rectangle.
///
/// Grabs the nearest [_ShimmerState] to paint with the shared gradient,
/// so every box inside the same [_Shimmer] sweeps together.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double? height;
  final double radius;

  const _SkeletonBox({required this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final shimmer = _Shimmer.of(context);
    final paint =
        shimmer?.gradient ??
        const LinearGradient(
          colors: [Color(0xFF222627), Color(0xFF2F3535), Color(0xFF222627)],
        );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: paint,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post card skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a single post card — mirrors the exact real card layout.
class PostCardSkeleton extends StatelessWidget {
  final bool animate;

  const PostCardSkeleton({super.key, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final card = _Shimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: ShapeDecoration(
          color: AppColors.cardFront,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.outline),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────
            Row(
              children: [
                // Avatar circle
                _SkeletonBox(width: 40, height: 40, radius: 9999),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      _SkeletonBox(width: 130, height: 12),
                      const SizedBox(height: 6),
                      // Subtitle (full name · time)
                      Row(
                        children: [
                          _SkeletonBox(width: 90, height: 10),
                          const SizedBox(width: 8),
                          _SkeletonBox(width: 40, height: 10),
                        ],
                      ),
                    ],
                  ),
                ),
                // More icon placeholder
                _SkeletonBox(width: 22, height: 22, radius: 6),
              ],
            ),
            const SizedBox(height: 12),

            // ── Image placeholder ─────────────────────────
            _SkeletonBox(width: double.infinity, height: 240, radius: 12),
            const SizedBox(height: 12),

            // ── Caption lines ─────────────────────────────
            _SkeletonBox(width: double.infinity, height: 11),
            const SizedBox(height: 7),
            _SkeletonBox(width: 200, height: 11),
            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────
            Row(
              children: [
                _SkeletonBox(width: 90, height: 34, radius: 9999),
                const SizedBox(width: 12),
                _SkeletonBox(width: 110, height: 34, radius: 9999),
              ],
            ),
          ],
        ),
      ),
    );

    if (!animate) return card;

    return _FadeSlideIn(child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed loading skeleton list
// ─────────────────────────────────────────────────────────────────────────────

/// Three post card skeletons that stagger-fade into view.
class FeedLoadingSkeleton extends StatelessWidget {
  const FeedLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _StaggeredFade(
          delay: Duration(milliseconds: index * 120),
          child: const PostCardSkeleton(animate: false),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a single comment row.
class CommentSkeleton extends StatelessWidget {
  const CommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 36, height: 36, radius: 9999),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBox(width: 110, height: 11),
                    const SizedBox(width: 8),
                    _SkeletonBox(width: 36, height: 10),
                  ],
                ),
                const SizedBox(height: 7),
                _SkeletonBox(width: double.infinity, height: 10),
                const SizedBox(height: 5),
                _SkeletonBox(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton list shown while comments are loading.
class CommentsLoadingSkeleton extends StatelessWidget {
  const CommentsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: List.generate(
          4,
          (i) => _StaggeredFade(
            delay: Duration(milliseconds: i * 80),
            child: const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CommentSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared animation helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Fades + slides a child up on mount — used for a single card.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  const _FadeSlideIn({required this.child});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

/// Wraps [_FadeSlideIn] with an optional [delay] before starting — used
/// to stagger skeleton cards in the list.
class _StaggeredFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggeredFade({required this.child, this.delay = Duration.zero});

  @override
  State<_StaggeredFade> createState() => _StaggeredFadeState();
}

class _StaggeredFadeState extends State<_StaggeredFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing dot (unchanged — kept for send-button usage)
// ─────────────────────────────────────────────────────────────────────────────

class PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  const PulsingDot({super.key, this.size = 8, this.color = AppColors.primary});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
