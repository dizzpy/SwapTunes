import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../screens/create_post_screen.dart';

class PostInputBox extends StatelessWidget {
  const PostInputBox({super.key});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = context.watch<AuthViewmodel>().currentUser?.avatarUrl;

    return GestureDetector(
      onTap: () {
        AppHaptics.uiTap();
        NavigationService.push(const CreatePostScreen());
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'post_creator_avatar',
                    child: _UserAvatar(avatarUrl: avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPaint(
                      painter: DashedCapsulePainter(color: AppColors.outline),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        child: const Text(
                          'What\'s on your mind ?',
                          style: AppTextStyles.bodySecondaryWhite,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.all(10),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: AppColors.textWhite,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? avatarUrl;

  const _UserAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: NetworkImage(avatarUrl!),
            fit: BoxFit.cover,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(
        color: AppColors.outline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: const Icon(Icons.person, color: AppColors.textSecondary, size: 22),
    );
  }
}

/// Custom painter for the dashed capsule border on the input placeholder.
class DashedCapsulePainter extends CustomPainter {
  final Color color;

  DashedCapsulePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 3;
    const double dashSpace = 3;

    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(size.height / 2),
    );

    final Path path = Path()..addRRect(rrect);

    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
