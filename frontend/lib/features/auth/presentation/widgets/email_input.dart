import 'package:flutter/material.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/input_box.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'otp_input.dart';

/// Bottom sheet widget that collects an email address and
/// sends an OTP code for passwordless authentication.
class EmailInput extends StatefulWidget {
  const EmailInput({super.key});

  @override
  State<EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends State<EmailInput> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);
    final auth = context.read<AuthViewmodel>();
    final success = await auth.sendOtp(email);

    if (mounted) {
      setState(() => _isSending = false);

      if (success) {
        // Close this sheet and open OTP input
        Navigator.of(context).pop();
        
        // Small delay to ensure sheet is closed before opening new one
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => const OtpInput(),
          );
        }
      } else {
        // Show error
        final error = auth.errorMessage ?? 'Failed to send code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.cardFront,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
          child: Column(
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
                AppStrings.onboarding.emailInputTitle,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),

              Text(
                AppStrings.onboarding.emailInputSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),

              // Email input
              InputBox(
                hintText: 'your@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMail01,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),

              // Send button
              PrimaryButton(
                text: _isSending
                    ? 'Sending...'
                    : AppStrings.onboarding.sendCodeBtn,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                onPressed: _isSending ? () {} : _sendOtp,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
