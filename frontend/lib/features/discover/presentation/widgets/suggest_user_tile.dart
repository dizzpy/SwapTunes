import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SuggestUserTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;

  const SuggestUserTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.isFollowing = false,
    this.isLoading = false,
    this.onFollow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          // Tapping avatar/name navigates to profile; follow button stays independent
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        avatarUrl != null && avatarUrl!.isNotEmpty
                            ? NetworkImage(avatarUrl!)
                            : null,
                    backgroundColor: AppColors.skeletonHighlight,
                    child:
                        avatarUrl == null || avatarUrl!.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: AppTextStyles.bodyPrimary,
                              )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            height: 36,
            child: ElevatedButton(
              onPressed: isLoading ? null : onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? Colors.transparent : AppColors.primary,
                foregroundColor:
                    isFollowing ? AppColors.textSecondary : AppColors.textWhite,
                elevation: 0,
                side:
                    isFollowing
                        ? const BorderSide(color: AppColors.outline)
                        : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.zero,
              ),
              child:
                  isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
