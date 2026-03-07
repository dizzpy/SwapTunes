// The entry point for SwapTunes frontend application.
//
// Manages application-wide setups, unified theme delegation, and root routing.
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwapTune',
      theme: AppTheme.darkTheme,
      home: const OnboardingScreen(),
    );
  }
}
