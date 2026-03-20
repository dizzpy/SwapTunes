import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Animated content area that switches based on the selected tab.
///
/// Displays placeholder text for Posts, Playlists, Songs tabs and a
/// sample collab card for the Collabs tab.
class ProfileTabContent extends StatelessWidget {
  final int selectedIndex;
  final bool isCreatorMode;

  const ProfileTabContent({
    super.key,
    required this.selectedIndex,
    required this.isCreatorMode,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (selectedIndex == 0) {
      content = _buildPlaceholder('Posts', 'Posts will appear here');
    } else if (!isCreatorMode && selectedIndex == 1) {
      content = _buildPlaceholder('Playlists', 'Playlists will appear here');
    } else if (isCreatorMode && selectedIndex == 2) {
      content = _buildPlaceholder('Songs', 'Songs will appear here');
    } else {
      content = _buildCollabCard();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: content,
    );
  }

  Widget _buildPlaceholder(String key, String message) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(message, style: AppTextStyles.bodySecondary),
      ),
    );
  }

  Widget _buildCollabCard() {
    return Container(
      key: const ValueKey('Collabs'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://picsum.photos/seed/mixing/100/100',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Mixing Engineer',
                  style: AppTextStyles.bodyPrimary,
                ),
                const SizedBox(height: 4),
                Text(
                  'I need a mixing engine...',
                  style: AppTextStyles.bodySecondary70,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.textWhite,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
