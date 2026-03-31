import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Placeholder screen for the Collaborations feature.
///
/// This tab is only visible to creators.
class CollabScreen extends StatelessWidget {
  const CollabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Collabs', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text('Coming soon', style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}
