import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:swaptune/core/theme/app_colors.dart';
import 'package:swaptune/features/auth/presentation/widgets/welcome_success_widgets.dart';
import 'package:swaptune/features/feed/presentation/screens/main_layout_screen.dart';

class WelcomeSuccessScreen extends StatefulWidget {
  const WelcomeSuccessScreen({super.key});

  @override
  State<WelcomeSuccessScreen> createState() => _WelcomeSuccessScreenState();
}

class _WelcomeSuccessScreenState extends State<WelcomeSuccessScreen> {
  bool _isConfettiPlaying = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerConfetti();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Plays a fast start haptic pattern that slowly fades out (~3s)
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

  // Triggers the celebratory confetti effect
  void _triggerConfetti() {
    if (_isConfettiPlaying) return;

    setState(() {
      _isConfettiPlaying = true;
    });

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

  // Handles the finalize action to enter the app shell
  void _onContinueTapped() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      (route) => false,
    );
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
                // Displays the welcome title and text
                const WelcomeTitleBox(),

                const Spacer(flex: 2),

                // Main action button to proceed
                WelcomeContinueBtn(onTap: _onContinueTapped),

                const SizedBox(height: 40),
              ],
            ),
          ),
          // Top-right button for manually replaying the confetti
          ConfettiReplayBtn(
            cooldownSeconds: _cooldownSeconds,
            isConfettiPlaying: _isConfettiPlaying,
            onReplay: _triggerConfetti,
          ),
        ],
      ),
    );
  }
}
