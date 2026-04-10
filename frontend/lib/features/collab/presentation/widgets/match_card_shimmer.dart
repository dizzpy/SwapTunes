import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MatchCardShimmer extends StatefulWidget {
  const MatchCardShimmer({super.key});

  @override
  State<MatchCardShimmer> createState() => _MatchCardShimmerState();
}

class _MatchCardShimmerState extends State<MatchCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      builder: (_, _) => _ShimmerCard(progress: _controller.value),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double progress;

  const _ShimmerCard({required this.progress});

  Widget _block({
    double width = double.infinity,
    double height = 14,
    double radius = 8,
  }) {
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        AppColors.skeletonBase,
        AppColors.skeletonHighlight,
        AppColors.skeletonBase,
      ],
      stops: [
        (progress - 0.3).clamp(0.0, 1.0),
        progress.clamp(0.0, 1.0),
        (progress + 0.3).clamp(0.0, 1.0),
      ],
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _block(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(width: 120, height: 14),
                    const SizedBox(height: 6),
                    _block(width: 80, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _block(width: 80, height: 30, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          _block(height: 12),
          const SizedBox(height: 6),
          _block(height: 12),
          const SizedBox(height: 6),
          _block(width: 200, height: 12),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _block(height: 44, radius: 14)),
              const SizedBox(width: 10),
              Expanded(child: _block(height: 44, radius: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
