import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashedCreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const DashedCreateButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.outline.withValues(alpha: 0.5),
          radius: 16.0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          color: Colors.transparent, // Required to make entire area clickable
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                AppStrings.collab.createNewCollab,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    Path path = Path()..addRRect(rrect);
    Path dashedPath = Path();

    const double dashWidth = 5.0;
    const double dashSpace = 5.0;

    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
