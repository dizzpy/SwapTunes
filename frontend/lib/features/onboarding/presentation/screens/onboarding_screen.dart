import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  SizedBox.expand(),
                  SizedBox.expand(),
                  SizedBox.expand(),
                ],
              ),
            ),

            // Page Indicator (dots) below the carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Sign-in button, only fully visible on the final page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentPage == 2 ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _currentPage != 2,
                  child: PrimaryButton(
                    text: AppStrings.onboarding.signInBtn,
                    backgroundColor: AppColors.cardFront,
                    foregroundColor: AppColors.textWhite,
                    onPressed: () {
                      _showAuthBottomSheet(context);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Displays the authentication options bottom sheet
  void _showAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return const AuthBottomSheet();
      },
    );
  }
}
