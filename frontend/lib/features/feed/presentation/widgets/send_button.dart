import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';

/// Animated circular send button that smoothly transitions between
/// an arrow icon and a sending indicator.
class SendButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onTap;

  const SendButton({super.key, required this.isSubmitting, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : () {
        AppHaptics.light();
        onTap?.call();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.sendButtonBg,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isSubmitting
              ? const SizedBox(
                  key: ValueKey('sending'),
                  width: 18,
                  height: 18,
                  child: WavyCircularIndicator(
                    color: AppColors.primary,
                    size: 18,
                    strokeWidth: 2.0,
                  ),
                )
              : const Icon(
                  key: ValueKey('idle'),
                  Icons.arrow_upward,
                  color: AppColors.primary,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
