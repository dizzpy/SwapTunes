import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../splash/presentation/screens/splash_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Bottom sheet widget for OTP verification.
///
/// Shows a single 8-digit input field that auto-verifies when complete.
/// Supports paste from clipboard and displays inline errors.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 8) return;
    AppHaptics.light();

    final auth = context.read<AuthViewmodel>();
    final success = await auth.verifyOtp(code);

    if (mounted) {
      if (success) {
        AppHaptics.success();
        // The auth state listener in AuthGate will handle the final navigation,
        // but fetching the profile takes a moment. Immediately show the Splash
        // screen as a loading state while we wait for _tryLoadProfile to finish.
        NavigationService.pushAndRemoveAll(const SplashScreen());
      }
      // If failed, error is already shown via Consumer
      if (!success) AppHaptics.error();
    }
  }

  Future<void> _resendOtp() async {
    final auth = context.read<AuthViewmodel>();
    final success = await auth.resendOtp();

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New code sent!'),
          backgroundColor: AppColors.cardFront,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Clear the input for new code
      _otpController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push up when keyboard opens
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: SafeArea(
          top: false,
          child: Consumer<AuthViewmodel>(
            builder: (context, auth, _) {
              final email = auth.pendingEmail ?? '';
              final error = auth.otpError;
              final isLoading = auth.isLoading;
              final canResend = auth.canResendOtp;
              final secondsRemaining = auth.resendSecondsRemaining;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    AppStrings.onboarding.otpTitle,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle with email
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.6),
                      ),
                      children: [
                        TextSpan(text: '${AppStrings.onboarding.otpSubtitle}\n'),
                        TextSpan(
                          text: email,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP input field (styled as boxes)
                  TextField(
                    controller: _otpController,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: AppTextStyles.heading1.copyWith(
                      letterSpacing: 16,
                      fontSize: 28,
                      color: AppColors.textWhite,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      counterText: '', // hide "0/8" counter
                      filled: true,
                      fillColor: AppColors.cardFront,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      hintText: '00000000',
                      hintStyle: AppTextStyles.heading1.copyWith(
                        letterSpacing: 16,
                        fontSize: 28,
                        color: AppColors.textWhite.withValues(alpha: 0.2),
                      ),
                    ),
                    onChanged: (value) {
                      // Auto-verify when 8 digits entered
                      if (value.length == 8) {
                        _verifyOtp();
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Error message (inline)
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Resend button with countdown
                  if (canResend)
                    TextButton(
                      onPressed: isLoading ? null : _resendOtp,
                      child: Text(
                        AppStrings.onboarding.otpResend,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${AppStrings.onboarding.otpResendIn} ${secondsRemaining}s',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.4),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Manual verify button (optional, for accessibility)
                  if (!isLoading)
                    PrimaryButton(
                      text: 'Verify Code',
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      onPressed: _otpController.text.length == 8
                          ? _verifyOtp
                          : () {},
                    )
                  else
                    PrimaryButton(
                      text: AppStrings.onboarding.otpVerifying,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      foregroundColor: AppColors.textWhite,
                      onPressed: () {},
                    ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
