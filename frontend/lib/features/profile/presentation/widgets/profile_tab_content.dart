import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../collab/data/models/collab_model.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/widgets/post_card.dart';

/// Animated content area that switches based on the selected tab.
class ProfileTabContent extends StatelessWidget {
  final int selectedIndex;
  final bool isCreatorMode;
  final bool isOwnProfile;

  // Posts tab data — passed from screen to avoid coupling with viewmodel
  final List<PostModel> posts;
  final bool isPostsLoading;
  final void Function(String postId)? onPostDeleted;

  // Collabs tab data
  final List<CollabModel> collabs;
  final bool isCollabsLoading;
  final void Function(CollabModel collab)? onCollabTap;

  const ProfileTabContent({
    super.key,
    required this.selectedIndex,
    required this.isCreatorMode,
    this.isOwnProfile = false,
    this.posts = const [],
    this.isPostsLoading = false,
    this.onPostDeleted,
    this.collabs = const [],
    this.isCollabsLoading = false,
    this.onCollabTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (selectedIndex == 0) {
      content = _buildPostsTab(context);
    } else if (!isCreatorMode && selectedIndex == 1) {
      content = _buildPlaceholder('Playlists', 'Playlists will appear here');
    } else if (isCreatorMode && selectedIndex == 2) {
      content = _buildPlaceholder('Songs', 'Songs will appear here');
    } else {
      content = _buildCollabsTab();
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

  Widget _buildPostsTab(BuildContext context) {
    if (isPostsLoading) {
      return const Center(
        key: ValueKey('PostsLoading'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: WavyCircularIndicator(color: AppColors.primary),
        ),
      );
    }
    if (posts.isEmpty) {
      return _buildPlaceholder('Posts', 'No posts yet');
    }
    return Column(
      key: const ValueKey('Posts'),
      children: posts.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PostCard(
            postId: post.id,
            userName: post.authorUsername,
            authorName: post.authorFullName,
            isVerified: post.authorIsVerified,
            avatarUrl: post.authorAvatarUrl ?? '',
            imageUrl: post.imageUrl,
            caption: post.content,
            likes: post.formattedLikes,
            comments: post.formattedComments,
            isLiked: post.isLiked,
            isOwnPost: isOwnProfile,
            timeAgo: post.timeAgo,
            onPostDeleted: isOwnProfile ? onPostDeleted : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCollabsTab() {
    if (isCollabsLoading) {
      return const Center(
        key: ValueKey('CollabsLoading'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: WavyCircularIndicator(color: AppColors.primary),
        ),
      );
    }
    if (collabs.isEmpty) {
      return _buildPlaceholder('Collabs', 'No collaborations yet');
    }
    return Column(
      key: const ValueKey('Collabs'),
      children: collabs.map((collab) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProfileCollabCard(
            collab: collab,
            onTap: onCollabTap != null ? () => onCollabTap!(collab) : null,
          ),
        );
      }).toList(),
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
}

/// Compact collab card designed for profile view.
class _ProfileCollabCard extends StatelessWidget {
  final CollabModel collab;
  final VoidCallback? onTap;

  const _ProfileCollabCard({required this.collab, this.onTap});

  IconData get _projectTypeIcon {
    switch (collab.paymentType) {
      case 'paid':
        return Icons.attach_money_rounded;
      case 'revenue_share':
        return Icons.trending_up_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Project type icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_projectTypeIcon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collab.title,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Looking for tags
                      Expanded(
                        child: Text(
                          collab.lookingFor.take(2).join(' • '),
                          style: AppTextStyles.bodySecondary.copyWith(
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Time ago
                      Text(
                        collab.timeAgo,
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Arrow indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
