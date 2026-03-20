import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Cover image with overlapping circular avatar.
///
/// Used by both [OwnProfileScreen] and [UserProfileScreen].
/// Avatar aligns left in creator mode, center in listener mode.
class ProfileCoverHeader extends StatelessWidget {
  final String coverUrl;
  final String avatarUrl;
  final bool isCreatorMode;

  const ProfileCoverHeader({
    super.key,
    required this.coverUrl,
    required this.avatarUrl,
    required this.isCreatorMode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment:
          isCreatorMode ? Alignment.bottomLeft : Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(coverUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: isCreatorMode ? 16 : null,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardFront,
              border: Border.all(color: AppColors.background, width: 6),
              image: DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
