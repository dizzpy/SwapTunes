import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../../../shared/widgets/app_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_background.dart';
import '../widgets/magic_link_input.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends a magic link to the entered email (replaces old email/password login).
  Future<void> _handleMagicLinkLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address'),
          backgroundColor: AppColors.cardFront,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final auth = context.read<AuthViewmodel>();
    final success = await auth.sendMagicLink(email);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Magic link sent to $email! Check your inbox.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
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

  /// Initiates Google OAuth sign-in.
  Future<void> _handleGoogleSignIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final auth = context.read<AuthViewmodel>();
    await auth.signInWithGoogle();

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  /// Initiates Spotify OAuth sign-in.
  Future<void> _handleSpotifySignIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final auth = context.read<AuthViewmodel>();
    await auth.signInWithSpotify();

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  /// Opens the magic link email modal.
  void _handleSignUpMagicLink() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MagicLinkInput(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AuthBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  Text(
                    AppStrings.auth.welcomeBack,
                    style: AppTextStyles.heading1,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    AppStrings.auth.loginToContinue,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.65),
                    ),
                  ),

                  const SizedBox(height: 40),

                  InputBox(
                    hintText: AppStrings.auth.emailHint,
                    controller: _emailController,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 30),

                  PrimaryButton(
                    text: 'Send Magic Link',
                    onPressed: _isProcessing ? () {} : _handleMagicLinkLogin,
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      AppStrings.auth.orContinueWith,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SocialButton(
                    text: AppStrings.auth.continueGoogle,
                    backgroundColor: AppColors.textWhite,
                    foregroundColor: AppColors.background,
                    icon: SvgPicture.asset(
                      'icons/google-logo.svg',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: _isProcessing ? () {} : _handleGoogleSignIn,
                  ),

                  const SizedBox(height: 12),

                  SocialButton(
                    text: AppStrings.auth.continueSpotify,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    icon: SvgPicture.asset(
                      'icons/spotify-logo.svg',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: _isProcessing ? () {} : _handleSpotifySignIn,
                  ),

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: _handleSignUpMagicLink,
                      child: Text.rich(
                        TextSpan(
                          text: AppStrings.auth.noAccount,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textWhite.withValues(alpha: 0.5),
                          ),
                          children: [
                            TextSpan(
                              text: AppStrings.auth.signUp,
                              style: AppTextStyles.bodyPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
