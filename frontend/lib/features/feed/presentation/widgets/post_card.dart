import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:swaptune/features/profile/presentation/screens/user_profile_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import 'post_options_sheet.dart';
import 'post_likes_sheet.dart';
import '../screens/post_preview_screen.dart';
import '../../../../core/services/navigation_service.dart';

class PostCard extends StatefulWidget {
  final String userName;
  final String authorName;
  final bool isVerified;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final String likes;
  final String comments;
  final bool isLiked;
  final bool isOwnPost;
  final bool showBackground;
  final bool showHeader;
  final bool showActionsBorder;
  final bool isTappable;
  final String? heroTag;

  const PostCard({
    super.key,
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
    this.showBackground = true,
    this.showHeader = true,
    this.showActionsBorder = true,
    this.isTappable = true,
    this.heroTag,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _navigateToPreview() {
    NavigationService.push(
      PostPreviewScreen(
        userName: widget.userName,
        authorName: widget.authorName,
        isVerified: widget.isVerified,
        avatarUrl: widget.avatarUrl,
        imageUrl: widget.imageUrl,
        caption: widget.caption,
        likes: widget.likes,
        comments: widget.comments,
        isLiked: _isLiked,
        isOwnPost: widget.isOwnPost,
        heroTag: widget.heroTag,
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
                      onTap: () => NavigationService.push(
                        UserProfileScreen(userName: widget.userName),
                      ),
                      child: _buildAvatar(),
                    ),
                    const SizedBox(width: 10),
                    // User Info
                    GestureDetector(
                      onTap: () => NavigationService.push(
                        UserProfileScreen(userName: widget.userName),
                      ),
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
                          Text(
                            widget.authorName,
                            style: AppTextStyles.bodySecondary70,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) =>
                          PostOptionsSheet(isOwnPost: widget.isOwnPost),
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
                icon: _isLiked
                    ? AppAssets.icon.favoriteFilled
                    : AppAssets.icon.favoriteOutline,
                iconColor: _isLiked ? AppColors.danger : AppColors.textWhite,
                label: widget.likes,
                showBorder: widget.showActionsBorder,
                onTap: _toggleLike,
                onLabelTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const PostLikesSheet(),
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
    return Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.avatarUrl),
          fit: BoxFit.cover,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    final imageWidget = Container(
      width: double.infinity,
      height: widget.showBackground ? 364 : null,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Image.network(
        widget.imageUrl,
        fit: widget.showBackground ? BoxFit.cover : BoxFit.fitWidth,
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'image_${widget.heroTag ?? widget.imageUrl}',
          child: imageWidget,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 217,
          child: Text(widget.caption, style: AppTextStyles.bodySecondary),
        ),
      ],
    );

    if (widget.isTappable) {
      return GestureDetector(
        onTap: _navigateToPreview,
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
          HapticFeedback.lightImpact();
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
              onTap: onLabelTap,
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
