import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swaptune/features/auth/presentation/screens/connect_spotify_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../widgets/genre_selection_wrap.dart';
import '../widgets/profile_avatar_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final Set<String> _selectedGenres = {};
  final List<String> _genres = [
    'Classical',
    'Dubstep',
    'Country',
    'Jazz',
    'Pop',
    'Indie',
    'Electronic',
    'Gospel',
  ];

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  Future<void> _handleCompleteProfile() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (fullName.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }

    if (_selectedGenres.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 genres.')),
      );
      return;
    }

    final success = await context.read<AuthViewmodel>().setupProfile(
      fullName: fullName,
      username: username,
      bio: bio.isNotEmpty ? bio : null,
      genres: _selectedGenres.toList(),
    );

    if (success && mounted) {
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ConnectSpotifyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (mounted) {
      final error = context.read<AuthViewmodel>().errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  AppStrings.profileSetup.title,
                  style: AppTextStyles.heading3,
                ),
              ),
              const SizedBox(height: 40),
              const Center(child: ProfileAvatarPicker()),
              const SizedBox(height: 40),

              // Text inputs for user details
              InputBox(
                controller: _fullNameController,
                title: AppStrings.profileSetup.fullNameLabel,
                hintText: AppStrings.profileSetup.fullNameHint,
              ),
              const SizedBox(height: 25),
              InputBox(
                controller: _usernameController,
                title: AppStrings.profileSetup.usernameLabel,
                hintText: AppStrings.profileSetup.usernameHint,
                prefixIcon: Text(
                  '@',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InputBox(
                controller: _bioController,
                title: AppStrings.profileSetup.bioLabel,
                hintText: AppStrings.profileSetup.bioHint,
                isMultiLine: true,
                characterCountText:
                    AppStrings.profileSetup.characterCountSuffix,
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.profileSetup.whatToListenInfo,
                    style: AppTextStyles.bodySecondary,
                  ),
                  Text(
                    AppStrings.profileSetup.pickCountInfo,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Wrap widget to select multiple favorite genres
              GenreSelectionWrap(
                availableGenres: _genres,
                selectedGenres: _selectedGenres,
                onGenreToggled: (genre) {
                  setState(() {
                    if (_selectedGenres.contains(genre)) {
                      _selectedGenres.remove(genre);
                    } else {
                      _selectedGenres.add(genre);
                    }
                  });
                },
              ),
              const SizedBox(height: 40),

              // Navigation button to proceed to Spotify connect screen
              Consumer<AuthViewmodel>(
                builder: (context, auth, _) {
                  return GreenButton(
                    text: auth.isLoading
                        ? 'Creating profile...'
                        : AppStrings.profileSetup.completeButton,
                    onPressed: auth.isLoading ? () {} : _handleCompleteProfile,
                    icon: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ));
  }
}
