import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/widgets/sliding_nav_bar.dart';

/// Bottom sheet displayed when the user taps the "+" icon on the Discover
/// Home app bar.
///
/// Presents two options: import from Spotify or create manually.
class AddPlaylistSheet extends StatelessWidget {
  final VoidCallback onImportFromSpotify;
  final VoidCallback onCreateManually;

  const AddPlaylistSheet({
    super.key,
    required this.onImportFromSpotify,
    required this.onCreateManually,
  });

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onImportFromSpotify,
    required VoidCallback onCreateManually,
  }) {
    AppHaptics.sheetOpen();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddPlaylistSheet(
        onImportFromSpotify: onImportFromSpotify,
        onCreateManually: onCreateManually,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + kNavBarHeight + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.discover.addPlaylistTitle,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: HugeIcons.strokeRoundedSpotify,
            title: AppStrings.discover.importFromSpotify,
            subtitle: AppStrings.discover.importFromSpotifySubtitle,
            accentColor: const Color(0xFF1DB954),
            onTap: () {
              Navigator.pop(context);
              onImportFromSpotify();
            },
          ),
          const SizedBox(height: 12),
          _SheetOption(
            icon: HugeIcons.strokeRoundedPlayListAdd,
            title: AppStrings.discover.createManually,
            subtitle: AppStrings.discover.createManuallySubtitle,
            accentColor: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              onCreateManually();
            },
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.buttonTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: HugeIcon(icon: icon, color: accentColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
