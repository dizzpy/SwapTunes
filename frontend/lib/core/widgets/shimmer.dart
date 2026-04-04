import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A widget that wraps [child] with an animated shimmer sweep.
///
/// Place any layout of [AppColors.skeletonBase]-coloured boxes inside [child]
/// and they will receive the travelling highlight automatically.
class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        // Sweep travels from -0.4 to 1.4 so it fully crosses any width
        final shimmerPos = -0.4 + t * 1.8;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.skeletonBase,
                AppColors.skeletonHighlight,
                AppColors.skeletonPeak,
                AppColors.skeletonHighlight,
                AppColors.skeletonBase,
              ],
              stops: [
                (shimmerPos - 0.35).clamp(0.0, 1.0),
                (shimmerPos - 0.15).clamp(0.0, 1.0),
                shimmerPos.clamp(0.0, 1.0),
                (shimmerPos + 0.15).clamp(0.0, 1.0),
                (shimmerPos + 0.35).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A single skeleton block — a rounded rectangle filled with [AppColors.skeletonBase].
/// Wrap a group of these in [AppShimmer] to animate them together.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A circular skeleton block (avatar placeholder).
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.skeletonBase,
        shape: BoxShape.circle,
      ),
    );
  }
}
