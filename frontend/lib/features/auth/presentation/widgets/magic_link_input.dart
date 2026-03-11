import 'package:flutter/material.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/input_box.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Bottom sheet widget that collects an email address and
/// sends a Supabase magic link for passwordless authentication.
class MagicLinkInput extends StatefulWidget {
  const MagicLinkInput({super.key});

  @override
  State<MagicLinkInput> createState() => _MagicLinkInputState();
}

class _MagicLinkInputState extends State<MagicLinkInput> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);
    final auth = context.read<AuthViewmodel>();
    final success = await auth.sendMagicLink(email);

    if (mounted) {
      setState(() {
        _isSending = false;
        _linkSent = success;
      });

      if (!success) {
        final error = auth.errorMessage ?? 'Failed to send magic link';
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
                _linkSent ? 'Check your inbox!' : 'Sign in with Magic Link',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),

              Text(
                _linkSent
                    ? 'We sent a login link to ${_emailController.text.trim()}. '
                          'Tap the link in the email to sign in.'
                    : 'Enter your email and we\'ll send you a magic link '
                          'to sign in instantly — no password needed.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),

              if (!_linkSent) ...[
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
                  text: _isSending ? 'Sending...' : 'Send Magic Link',
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  onPressed: _isSending ? () {} : _sendMagicLink,
                ),
              ] else ...[
                // Success state — allow resending
                Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.primary,
                  size: 64,
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: _isSending ? null : _sendMagicLink,
                  child: Text(
                    'Resend link',
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
