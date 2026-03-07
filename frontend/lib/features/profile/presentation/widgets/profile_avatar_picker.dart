// lib/features/profile/presentation/widgets/profile_avatar_picker.dart
// Tappable avatar widget that opens a photo-source picker bottom sheet.

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:swaptune/core/theme/app_colors.dart';
import 'profile_image_picker_sheet.dart';

/// Displays a circular avatar placeholder with a camera badge.
/// Tapping the badge opens the [ProfileImagePickerSheet].
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Avatar circle ─────────────────────────
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textWhite.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                size: 50,
                color: AppColors.textWhite.withValues(alpha: 0.3),
              ),
            ),
          ),

          // ── Camera badge (tappable) ────────────────
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => showProfileImagePickerSheet(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 4),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
