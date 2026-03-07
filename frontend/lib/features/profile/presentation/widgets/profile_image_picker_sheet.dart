// lib/features/profile/presentation/widgets/profile_image_picker_sheet.dart
// Bottom sheet for choosing a profile photo source (camera or gallery).

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shows a modal bottom sheet with options to pick a profile image.
void showProfileImagePickerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const ProfileImagePickerSheet(),
  );
}

/// Bottom sheet that lets the user choose between camera and gallery
/// for their profile photo. Removing the photo is also supported.
class ProfileImagePickerSheet extends StatelessWidget {
  const ProfileImagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────
            _DragHandle(),

            const SizedBox(height: 24),

            // ── Header ───────────────────────────────
            Text('Profile Photo', style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            Text(
              'Choose how you want to upload your photo',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // ── Options ──────────────────────────────
            _PickerOption(
              icon: HugeIcons.strokeRoundedCamera01,
              label: 'Take a Photo',
              subtitle: 'Use your camera',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: open camera
              },
            ),

            const SizedBox(height: 12),

            _PickerOption(
              icon: HugeIcons.strokeRoundedImage01,
              label: 'Choose from Gallery',
              subtitle: 'Pick from your photo library',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: open gallery
              },
            ),

            const SizedBox(height: 12),

            _PickerOption(
              icon: HugeIcons.strokeRoundedDelete01,
              label: 'Remove Photo',
              subtitle: 'Reset to default avatar',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                // TODO: remove photo
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private Widgets ──────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDanger ? AppColors.danger : AppColors.primary;
    final labelColor = isDanger ? AppColors.danger : AppColors.textWhite;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDanger
                ? AppColors.danger.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDanger
                  ? AppColors.danger.withValues(alpha: 0.2)
                  : AppColors.outline,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(icon: icon, color: iconColor, size: 20),
                ),
              ),

              const SizedBox(width: 14),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: labelColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),

              // Chevron
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
