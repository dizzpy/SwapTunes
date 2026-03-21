import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:swaptune/features/profile/presentation/screens/user_profile_screen.dart';

import '../screens/main_layout_screen.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/feed_viewmodel.dart';
import '../screens/post_preview_screen.dart';
import '../screens/edit_post_screen.dart';
import 'post_likes_sheet.dart';
import 'post_options_sheet.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String userName;
  final String authorName;
  final bool isVerified;
  final String avatarUrl;
  final String? imageUrl;
  final String caption;
  final String likes;
  final String comments;
  final bool isLiked;
  final bool isOwnPost;
  final void Function(String postId)? onPostDeleted;
  final bool showBackground;
  final bool showHeader;
  final bool showActionsBorder;
  final bool isTappable;
  final String? heroTag;
  final String timeAgo;

  const PostCard({
    super.key,
    required this.postId,
    required this.userName,
    required this.authorName,
    required this.isVerified,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.isOwnPost = false,
    this.onPostDeleted,
    this.showBackground = true,
    this.showHeader = true,
    this.showActionsBorder = true,
    this.isTappable = true,
    this.heroTag,
    this.timeAgo = '',
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  void _navigateToAuthorProfile() {
    AppHaptics.uiTap();
    final myUsername = context.read<AuthViewmodel>().currentUser?.username;
    if (myUsername != null && myUsername == widget.userName) {
      MainLayoutScreen.switchToProfile();
    } else {
      NavigationService.push(UserProfileScreen(username: widget.userName));
    }
  }

  void _toggleLike() {
    AppHaptics.like();
    context.read<FeedViewmodel>().toggleLike(widget.postId);
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final feedVm = context.read<FeedViewmodel>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete post',
      message: 'This will permanently remove your post.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      await feedVm.deletePost(widget.postId);
      widget.onPostDeleted?.call(widget.postId);
      AppSnackbar.success('Post deleted');
    }
  }

  void _openEditPost() {
    NavigationService.push(
      EditPostScreen(
        postId: widget.postId,
        initialContent: widget.caption,
        initialImageUrl: widget.imageUrl,
      ),
    );
  }

  void _navigateToPreview() {
    NavigationService.push(
      PostPreviewScreen(
        postId: widget.postId,
        userName: widget.userName,
        authorName: widget.authorName,
        isVerified: widget.isVerified,
        avatarUrl: widget.avatarUrl,
        imageUrl: widget.imageUrl,
        caption: widget.caption,
        likes: widget.likes,
        comments: widget.comments,
        isLiked: widget.isLiked,
        isOwnPost: widget.isOwnPost,
        heroTag: widget.heroTag,
        timeAgo: widget.timeAgo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: widget.showBackground
          ? const EdgeInsets.all(15)
          : const EdgeInsets.symmetric(horizontal: 0),
      decoration: widget.showBackground
          ? ShapeDecoration(
              color: AppColors.cardFront,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: AppColors.outline),
                borderRadius: BorderRadius.circular(18),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _navigateToAuthorProfile,
                      child: _buildAvatar(),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _navigateToAuthorProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.userName,
                                style: AppTextStyles.bodyPrimary,
                              ),
                              if (widget.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                widget.authorName,
                                style: AppTextStyles.bodySecondary70,
                              ),
                              if (widget.timeAgo.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '· ${widget.timeAgo}',
                                  style: AppTextStyles.bodySecondary70,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    AppHaptics.sheetOpen();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (ctx) => PostOptionsSheet(
                        isOwnPost: widget.isOwnPost,
                        onEdit: _openEditPost,
                        onDelete: () => _confirmDeletePost(context),
                        onHide: () => context.read<FeedViewmodel>().hidePost(
                          widget.postId,
                        ),
                        onReport: () => context
                            .read<FeedViewmodel>()
                            .reportPost(widget.postId, 'inappropriate'),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: HugeIcon(
                      icon: AppAssets.icon.more,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          _buildPostContent(),
          const SizedBox(height: 10),

          Row(
            children: [
              _PostActionButton(
                icon: widget.isLiked
                    ? AppAssets.icon.favoriteFilled
                    : AppAssets.icon.favoriteOutline,
                iconColor: widget.isLiked
                    ? AppColors.danger
                    : AppColors.textWhite,
                label: widget.likes,
                showBorder: widget.showActionsBorder,
                onTap: _toggleLike,
                onLabelTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => PostLikesSheet(postId: widget.postId),
                  );
                },
              ),
              SizedBox(width: widget.showBackground ? 12 : 18),
              _PostActionButton(
                icon: AppAssets.icon.comment,
                iconColor: AppColors.textWhite,
                label: widget.comments,
                showBorder: widget.showActionsBorder,
                onTap: widget.isTappable ? _navigateToPreview : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final hasUrl = widget.avatarUrl.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: widget.avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(width: 40, height: 40, color: AppColors.outline),
              errorWidget: (context, url, error) => Container(
                width: 40,
                height: 40,
                color: AppColors.outline,
                child: const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              color: AppColors.outline,
              child: const Icon(
                Icons.person,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
    );
  }

  Widget _buildPostContent() {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          Hero(
            tag: 'image_${widget.heroTag ?? widget.imageUrl}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                width: double.infinity,
                height: widget.showBackground ? 364 : null,
                fit: widget.showBackground ? BoxFit.cover : BoxFit.fitWidth,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: widget.showBackground ? 364 : 200,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: widget.showBackground ? 364 : 200,
                  color: AppColors.outline,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        if (hasImage) const SizedBox(height: 10),
        SizedBox(
          width: 217,
          child: Text(widget.caption, style: AppTextStyles.bodySecondary),
        ),
      ],
    );

    if (widget.isTappable) {
      return GestureDetector(
        onTap: () {
          AppHaptics.uiTap();
          _navigateToPreview();
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

class _PostActionButton extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLabelTap;
  final bool showBorder;

  const _PostActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
    this.onLabelTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          AppHaptics.buttonTap();
          onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: showBorder
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(vertical: 8),
        decoration: showBorder
            ? ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: AppColors.outline),
                  borderRadius: BorderRadius.circular(9999),
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onLabelTap != null
                  ? () {
                      AppHaptics.sheetOpen();
                      onLabelTap!();
                    }
                  : null,
              child: Text(label, style: AppTextStyles.bodySecondaryWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (icon is IconData) {
      return Icon(icon, color: iconColor, size: 16);
    }
    return HugeIcon(icon: icon, color: iconColor, size: 16);
  }
}
