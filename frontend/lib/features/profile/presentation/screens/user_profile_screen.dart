import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;

  const UserProfileScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.cardFront,
              child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: AppTextStyles.heading1.copyWith(color: AppColors.textWhite),
            ),
            const SizedBox(height: 10),
            Text(
              'Profile Page (Coming Soon)',
              style: AppTextStyles.bodySecondary70,
            ),
          ],
        ),
      ),
    );
  }
}
