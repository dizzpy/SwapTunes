import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.authBgTop, AppColors.authBgBottom],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.7),
              radius: 1.3,
              colors: [
                AppColors.authGlow.withValues(alpha: 0.55),
                AppColors.transparent,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.9),
              radius: 1.6,
              colors: [
                AppColors.authGlow.withValues(alpha: 0.25),
                AppColors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
