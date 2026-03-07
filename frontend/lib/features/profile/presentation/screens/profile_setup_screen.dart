import 'package:flutter/material.dart';
import 'package:swaptune/features/auth/presentation/screens/connect_spotify_screen.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../../../shared/widgets/app_button.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                title: AppStrings.profileSetup.fullNameLabel,
                hintText: AppStrings.profileSetup.fullNameHint,
              ),
              const SizedBox(height: 25),
              InputBox(
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
              GreenButton(
                text: AppStrings.profileSetup.completeButton,
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ConnectSpotifyScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
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
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
