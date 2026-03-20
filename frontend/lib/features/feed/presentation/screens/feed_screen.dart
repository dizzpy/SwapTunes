import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/post_model.dart';
import '../../presentation/viewmodels/feed_viewmodel.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/post_card.dart';
import '../widgets/post_input_box.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewmodel>().loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedViewmodel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = context.watch<FeedViewmodel>();
    final currentUserId = context.watch<AuthViewmodel>().currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppIconButton(
                  icon: AppAssets.icon.menu,
                  variant: AppIconButtonVariant.filled,
                ),
                AppIconButton(
                  icon: AppAssets.icon.notification,
                  variant: AppIconButtonVariant.filled,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardFront,
        onRefresh: () => context.read<FeedViewmodel>().loadFeed(),
        child: _buildBody(feedVm, currentUserId),
      ),
    );
  }

  Widget _buildBody(FeedViewmodel feedVm, String? currentUserId) {
    if (feedVm.isLoading) {
      return const FeedLoadingSkeleton();
    }

    if (feedVm.feedError != null && feedVm.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feedVm.feedError!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<FeedViewmodel>().loadFeed(),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: feedVm.posts.length + 2, // +1 header (input box) +1 footer
      itemBuilder: (context, index) {
        // Header — post input box
        if (index == 0) {
          return const Column(
            children: [
              PostInputBox(),
              SizedBox(height: 24),
            ],
          );
        }

        // Footer — loading skeleton or end padding
        if (index == feedVm.posts.length + 1) {
          if (feedVm.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: PostCardSkeleton(),
            );
          }
          return const SizedBox(height: 80);
        }

        final post = feedVm.posts[index - 1];
        return _PostItem(post: post, currentUserId: currentUserId);
      },
    );
  }
}

class _PostItem extends StatelessWidget {
  final PostModel post;
  final String? currentUserId;

  const _PostItem({required this.post, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (post.isUploading) {
      return _UploadingPostCard(post: post);
    }
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
        isOwnPost: post.userId == currentUserId,
        heroTag: 'post_${post.id}',
        timeAgo: post.timeAgo,
      ),
    );
  }
}

/// Shows the post content with a reduced opacity and a progress bar
/// while the post is being uploaded.
class _UploadingPostCard extends StatelessWidget {
  final PostModel post;
  const _UploadingPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: 0.6,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: ShapeDecoration(
            color: AppColors.cardFront,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: AppColors.outline),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.authorAvatarUrl != null
                        ? NetworkImage(post.authorAvatarUrl!)
                        : null,
                    backgroundColor: AppColors.outline,
                    child: post.authorAvatarUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.textSecondary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorUsername,
                          style: AppTextStyles.bodyPrimary),
                      const SizedBox(height: 2),
                      Text('Publishing...',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Caption preview
              if (post.content.isNotEmpty)
                Text(post.content, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 12),
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: AppColors.outline,
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
