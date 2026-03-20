import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Public profile screen — pushed via navigation when tapping a user's
/// avatar/username on feed posts, search results, etc.
///
/// Shows another user's profile with Follow/Unfollow button.
/// Auto-detects if viewing own profile and shows Edit Profile instead.
/// Conditionally renders creator sections based on user_type.
class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textWhite,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          '@${widget.username}',
          style: AppTextStyles.bodySecondary70,
        ),
      ),
    );
  }
}
