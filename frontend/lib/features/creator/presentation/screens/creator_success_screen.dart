import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/feed/presentation/screens/main_layout_screen.dart';

class CreatorSuccessScreen extends StatefulWidget {
  const CreatorSuccessScreen({super.key});

  @override
  State<CreatorSuccessScreen> createState() => _CreatorSuccessScreenState();
}

class _CreatorSuccessScreenState extends State<CreatorSuccessScreen> {
  bool _isConfettiPlaying = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerConfetti());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _playCalmHapticPattern() async {
    if (!mounted) return;

    final pattern = <Future<void> Function()>[
      () => HapticFeedback.selectionClick(),
      () => HapticFeedback.selectionClick(),
      () => HapticFeedback.lightImpact(),
      () => HapticFeedback.selectionClick(),
      () => HapticFeedback.lightImpact(),
      () => HapticFeedback.mediumImpact(),
      () => HapticFeedback.lightImpact(),
      () => HapticFeedback.selectionClick(),
      () => HapticFeedback.selectionClick(),
      () => HapticFeedback.selectionClick(),
    ];

    final delays = [60, 80, 100, 130, 170, 220, 280, 340, 420, 520];

    for (int i = 0; i < pattern.length; i++) {
      if (!mounted) break;
      await pattern[i]();
      await Future.delayed(Duration(milliseconds: delays[i]));
    }
  }

  void _triggerConfetti() {
    if (_isConfettiPlaying) return;

    setState(() => _isConfettiPlaying = true);

    _playCalmHapticPattern();

    Confetti.launch(
      context,
      options: const ConfettiOptions(
        particleCount: 300,
        spread: 90,
        y: 0.8,
        colors: [
          AppColors.success,
          AppColors.primary,
          AppColors.textWhite,
          AppColors.warning,
          AppColors.danger,
        ],
      ),
    );

    _cooldownSeconds = 3;
    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
        } else {
          _cooldownSeconds = 0;
          _isConfettiPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _onGoToProfile() {
    MainLayoutScreen.switchToProfile();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.75,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.greenGradient,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppStrings.creator.creatorSuccessTitle,
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.creator.creatorSuccessSubtitle,
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.textWhite,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: InkWell(
                    onTap: _onGoToProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.cardFront,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          AppStrings.creator.goToProfileBtn,
                          style: AppTextStyles.bodyPrimary.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
