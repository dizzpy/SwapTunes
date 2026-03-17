import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:swaptune/features/profile/presentation/screens/user_profile_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../widgets/post_card.dart';
import '../widgets/post_options_sheet.dart';
import '../../../../core/services/navigation_service.dart';

class PostPreviewScreen extends StatelessWidget {
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
  final String? heroTag;

  const PostPreviewScreen({
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
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Mock comments for UI demonstration
    final List<Map<String, String>> mockComments = [
      {
        'user': 'Julianna',
        'avatar': 'https://i.pravatar.cc/150?u=10',
        'text': 'This is such a vibe! Love the aesthetic. ✨',
        'time': '2h',
        'isOwn': 'false',
      },
      {
        'user': 'Mike Ross',
        'avatar': 'https://i.pravatar.cc/150?u=12',
        'text': 'The lighting in this shot is incredible.',
        'time': '1h',
        'isOwn': 'false',
      },
      {
        'user': 'Dizzpy Sanchez',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'text': 'Thanks for the love guys! ❤️',
        'time': '15m',
        'isOwn': 'true',
      },
      {
        'user': 'Sarah',
        'avatar': 'https://i.pravatar.cc/150?u=15',
        'text': 'Can we get a BTS of this?',
        'time': '5m',
        'isOwn': 'false',
      },
    ];

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
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () =>
              NavigationService.push(UserProfileScreen(userName: userName)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  Text(authorName, style: AppTextStyles.caption),
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
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => PostOptionsSheet(isOwnPost: isOwnPost),
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
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Post without Card Background and Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: PostCard(
                      userName: userName,
                      authorName: authorName,
                      isVerified: isVerified,
                      avatarUrl: avatarUrl,
                      imageUrl: imageUrl,
                      caption: caption,
                      likes: likes,
                      comments: comments,
                      isLiked: isLiked,
                      isOwnPost: isOwnPost,
                      showBackground: false,
                      showHeader: false, // Moved to AppBar
                      showActionsBorder: false, // Minimal Style
                      isTappable: false, // FIXED: Disable infinite navigation
                      heroTag: heroTag,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Comments Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Text('Comments', style: AppTextStyles.bodyPrimary),
                        const SizedBox(width: 8),
                        Text(comments, style: AppTextStyles.bodySecondary70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Comments List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    itemCount: mockComments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final comment = mockComments[index];
                      return _CommentTile(
                        user: comment['user']!,
                        avatar: comment['avatar']!,
                        text: comment['text']!,
                        time: comment['time']!,
                        isOwn: comment['isOwn'] == 'true',
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Refined Comment Input Area
          _CommentInputArea(),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String user;
  final String avatar;
  final String text;
  final String time;
  final bool isOwn;

  const _CommentTile({
    required this.user,
    required this.avatar,
    required this.text,
    required this.time,
    required this.isOwn,
  });

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
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
                  icon: AppAssets.icon.delete,
                  label: 'Delete comment',
                  iconColor: AppColors.danger,
                  textColor: AppColors.danger,
                  onTap: () {
                    // TODO: Implement delete
                    Navigator.pop(context);
                  },
                ),
              ] else ...[
                _OptionTile(
                  icon: Icons.copy,
                  label: 'Copy text',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
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
                _OptionTile(
                  icon: AppAssets.icon.report,
                  label: 'Report comment',
                  iconColor: AppColors.danger,
                  textColor: AppColors.danger,
                  onTap: () {
                    // TODO: Implement report
                    Navigator.pop(context);
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
            onTap: () =>
                NavigationService.push(UserProfileScreen(userName: user)),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(avatar),
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
                      onTap: () => NavigationService.push(
                        UserProfileScreen(userName: user),
                      ),
                      child: Text(
                        user,
                        style: AppTextStyles.bodyPrimary.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.bodySecondaryWhite),
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
      onTap: onTap,
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
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1B2B24), // Dark subtle green for the brand
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
