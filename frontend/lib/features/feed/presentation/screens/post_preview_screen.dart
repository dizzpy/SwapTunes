import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:swaptune/features/profile/presentation/screens/user_profile_screen.dart';

import 'main_layout_screen.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/comment_model.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/post_card.dart';
import '../widgets/edit_content_sheet.dart';
import '../widgets/post_options_sheet.dart';
import '../widgets/send_button.dart';
import 'edit_post_screen.dart';

class PostPreviewScreen extends StatefulWidget {
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
  final String? heroTag;
  final String timeAgo;

  const PostPreviewScreen({
    super.key,
    required this.postId,
    required this.userName,
    required this.authorName,
    required this.isVerified,
    required this.avatarUrl,
    this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.isOwnPost = false,
    this.heroTag,
    this.timeAgo = '',
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _navigateToProfile(String username) {
    AppHaptics.uiTap();
    final myUsername = context.read<AuthViewmodel>().currentUser?.username;
    if (myUsername != null && myUsername == username) {
      MainLayoutScreen.switchToProfile();
    } else {
      NavigationService.push(UserProfileScreen(username: username));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewmodel>().loadComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final feedVm = context.read<FeedViewmodel>();
    final nav = Navigator.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete post',
      message: 'This will permanently remove your post.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      await feedVm.deletePost(widget.postId);
      AppSnackbar.success('Post deleted');
      nav.pop();
    }
  }

  void _openEditPost() {
    final feedVm = context.read<FeedViewmodel>();
    final post = feedVm.posts.where((p) => p.id == widget.postId).firstOrNull;
    NavigationService.push(
      EditPostScreen(
        postId: widget.postId,
        initialContent: post?.content ?? widget.caption,
        initialImageUrl: post?.imageUrl ?? widget.imageUrl,
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    AppHaptics.success();

    final authVm = context.read<AuthViewmodel>();
    final user = authVm.currentUser;

    // UI Update First: Clear immediately
    _commentController.clear();

    // Scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Logic: Trigger addComment (which internally performs optimistic UI update)
    context.read<FeedViewmodel>().addComment(
      widget.postId,
      text,
      userId: user?.id ?? '',
      authorUsername: user?.username ?? '',
      authorFullName: user?.fullName ?? '',
      authorAvatarUrl: user?.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = context.watch<FeedViewmodel>();
    final currentUserId = context.watch<AuthViewmodel>().currentUser?.id;

    final postIndex = feedVm.posts.indexWhere((p) => p.id == widget.postId);
    final livePost = postIndex != -1 ? feedVm.posts[postIndex] : null;
    final liveLikes = livePost?.formattedLikes ?? widget.likes;
    final liveComments = livePost?.formattedComments ?? widget.comments;
    final liveIsLiked = livePost?.isLiked ?? widget.isLiked;
    final liveTimeAgo = livePost?.timeAgo ?? widget.timeAgo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textWhite,
            size: 24,
          ),
          onPressed: () {
            AppHaptics.uiTap();
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () => _navigateToProfile(widget.userName),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.avatarUrl),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.userName,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
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
                  Row(
                    children: [
                      Text(widget.authorName, style: AppTextStyles.caption),
                      if (liveTimeAgo.isNotEmpty) ...[
                        Text(' · $liveTimeAgo', style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: AppAssets.icon.more,
              color: AppColors.textWhite,
              size: 24,
            ),
            onPressed: () {
              AppHaptics.sheetOpen();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => PostOptionsSheet(
                  isOwnPost: widget.isOwnPost,
                  onEdit: _openEditPost,
                  onDelete: () => _confirmDeletePost(context),
                  onHide: () {
                    final nav = Navigator.of(context);
                    context
                        .read<FeedViewmodel>()
                        .hidePost(widget.postId)
                        .then((_) => nav.pop());
                  },
                  onReport: () => context.read<FeedViewmodel>().reportPost(
                    widget.postId,
                    'inappropriate',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: PostCard(
                      postId: widget.postId,
                      userName: widget.userName,
                      authorName: widget.authorName,
                      isVerified: widget.isVerified,
                      avatarUrl: widget.avatarUrl,
                      imageUrl: widget.imageUrl,
                      caption: widget.caption,
                      likes: liveLikes,
                      comments: liveComments,
                      isLiked: liveIsLiked,
                      isOwnPost: widget.isOwnPost,
                      showBackground: false,
                      showHeader: false,
                      showActionsBorder: false,
                      isTappable: false,
                      heroTag: widget.heroTag,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Text('Comments', style: AppTextStyles.bodyPrimary),
                        const SizedBox(width: 8),
                        Text(
                          liveComments,
                          style: AppTextStyles.bodySecondary70,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCommentsList(feedVm, currentUserId),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _CommentInputArea(
            controller: _commentController,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(FeedViewmodel feedVm, String? currentUserId) {
    if (feedVm.isCommentsLoading) {
      return const CommentsLoadingSkeleton();
    }

    if (feedVm.commentError != null && feedVm.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feedVm.commentError!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => feedVm.loadComments(widget.postId),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (feedVm.comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No comments yet. Be the first!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: feedVm.comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final comment = feedVm.comments[index];
        return _CommentTile(
          comment: comment,
          isOwn: comment.userId == currentUserId,
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isOwn;

  const _CommentTile({required this.comment, required this.isOwn});

  void _navigateToProfile(BuildContext context, String username) {
    AppHaptics.uiTap();
    final myUsername = context.read<AuthViewmodel>().currentUser?.username;
    if (myUsername != null && myUsername == username) {
      MainLayoutScreen.switchToProfile();
    } else {
      NavigationService.push(UserProfileScreen(username: username));
    }
  }

  Future<void> _confirmDeleteComment(BuildContext context) async {
    final feedVm = context.read<FeedViewmodel>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete comment',
      message: 'This comment will be permanently removed.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (confirmed == true) {
      await feedVm.deleteComment(comment.postId, comment.id);
      AppSnackbar.success('Comment deleted');
    }
  }

  void _showEditCommentSheet(BuildContext context) {
    final feedVm = context.read<FeedViewmodel>();
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditContentSheet(
        initialContent: comment.content,
        title: 'Edit comment',
        maxLength: 500,
      ),
    ).then((newContent) {
      if (newContent != null && newContent.isNotEmpty) {
        feedVm.updateComment(comment.postId, comment.id, newContent);
      }
    });
  }

  void _showOptions(BuildContext context) {
    AppHaptics.longPress();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (isOwn) ...[
                _OptionTile(
                  icon: AppAssets.icon.edit,
                  label: 'Edit comment',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditCommentSheet(context);
                  },
                ),
                const SizedBox(height: 8),
                _OptionTile(
                  icon: AppAssets.icon.delete,
                  label: 'Delete comment',
                  iconColor: AppColors.danger,
                  textColor: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteComment(context);
                  },
                ),
              ] else ...[
                _OptionTile(
                  icon: Icons.copy,
                  label: 'Copy text',
                  onTap: () {
                    AppHaptics.buttonTap();
                    Clipboard.setData(ClipboardData(text: comment.content));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, comment.authorUsername),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: comment.authorAvatarUrl != null
                  ? NetworkImage(comment.authorAvatarUrl!)
                  : null,
              backgroundColor: AppColors.cardFront,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _navigateToProfile(context, comment.authorUsername),
                      child: Text(
                        comment.authorUsername,
                        style: AppTextStyles.bodyPrimary.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(comment.timeAgo, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: AppTextStyles.bodySecondaryWhite),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.buttonTap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            if (icon is IconData)
              Icon(icon, color: iconColor ?? AppColors.textWhite, size: 24)
            else
              HugeIcon(
                icon: icon,
                color: iconColor ?? AppColors.textWhite,
                size: 24,
              ),
            const SizedBox(width: 15),
            Text(
              label,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: textColor ?? AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CommentInputArea({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyPrimary.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 10),
            SendButton(
              isSubmitting:
                  false, // Never show progress indicator as per user request
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
