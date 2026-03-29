import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/navigation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Global snackbar utility. Works without a BuildContext by using
/// [NavigationService.navigatorKey].
///
/// Usage:
///   AppSnackbar.success('Post deleted');
///   AppSnackbar.error('Something went wrong');
class AppSnackbar {
  AppSnackbar._();

  static void success(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
    iconColor: AppColors.primary,
  );

  static void error(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedAlert02,
    iconColor: AppColors.danger,
  );

  static void info(String message) => _show(
    message: message,
    icon: HugeIcons.strokeRoundedInformationCircle,
    iconColor: AppColors.textSecondary,
  );

  static void withUndo({
    required String message,
    required VoidCallback onUndo,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 5),
          content: _UndoSnackbarContent(
            message: message,
            onUndo: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              onUndo();
            },
          ),
        ),
      );
  }

  static void _show({
    required String message,
    required dynamic icon,
    required Color iconColor,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline, width: 0.8),
            ),
            child: Row(
              children: [
                HugeIcon(icon: icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: AppTextStyles.bodySecondaryWhite),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _UndoSnackbarContent extends StatefulWidget {
  final String message;
  final VoidCallback onUndo;

  const _UndoSnackbarContent({
    required this.message,
    required this.onUndo,
  });

  @override
  State<_UndoSnackbarContent> createState() => _UndoSnackbarContentState();
}

class _UndoSnackbarContentState extends State<_UndoSnackbarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 0.8),
      ),
      child: Row(
        children: [
          // Circular countdown ring with remaining seconds in center
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final seconds =
                  (5 * (1.0 - _controller.value)).ceil().clamp(0, 5);
              return SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0 - _controller.value,
                      strokeWidth: 3,
                      backgroundColor: AppColors.outline,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.danger),
                    ),
                    Center(
                      child: Text(
                        '$seconds',
                        style: AppTextStyles.bodySecondaryWhite.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: AppTextStyles.bodySecondaryWhite,
            ),
          ),
          TextButton(
            onPressed: widget.onUndo,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Undo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
