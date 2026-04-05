import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../notifications/data/datasources/notification_datasource.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/viewmodels/notification_viewmodel.dart';
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
  late final NotificationViewmodel _notificationVm;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final apiClient = context.read<ApiClient>();
    final currentUserId = context.read<StorageService>().getUserId() ?? '';
    _notificationVm = NotificationViewmodel(
      NotificationRepository(NotificationDatasource(apiClient)),
      currentUserId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewmodel>().loadFeed();
      _notificationVm.loadNotifications();
      _notificationVm.subscribeToNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationVm.dispose();
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
      body: CustomMaterialIndicator(
        onRefresh: () => context.read<FeedViewmodel>().loadFeed(),
        backgroundColor: AppColors.cardFront,
        indicatorBuilder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: WavyCircularIndicator(
              size: 36,
              strokeWidth: 3.0,
              color: AppColors.primary,
              waveCount: 14,
              amplitudeFactor: 0.4,
              arcFraction: 1.0,
              showTrack: false,
            ),
          );
        },
        child: _buildBody(feedVm, currentUserId),
      ),
    );
  }

  Widget _buildBody(FeedViewmodel feedVm, String? currentUserId) {
    if (feedVm.isLoading) {
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          const SliverFillRemaining(child: FeedLoadingSkeleton()),
        ],
      );
    }

    if (feedVm.feedError != null && feedVm.posts.isEmpty) {
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
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
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Header — post input box
                if (index == 0) {
                  return const Column(
                    children: [PostInputBox(), SizedBox(height: 24)],
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
                  return const SizedBox(height: 100);
                }

                final post = feedVm.posts[index - 1];
                return _PostItem(post: post, currentUserId: currentUserId);
              },
              childCount:
                  feedVm.posts.length + 2, // +1 header (input box) +1 footer
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppIconButton(
              icon: AppAssets.icon.menu,
              variant: AppIconButtonVariant.filled,
              size: 44,
            ),
            ListenableBuilder(
              listenable: _notificationVm,
              builder: (context, _) {
                final count = _notificationVm.unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppIconButton(
                      icon: AppAssets.icon.notification,
                      variant: AppIconButtonVariant.filled,
                      size: 44,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: _notificationVm,
                            child: const NotificationsScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
                        ? const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        style: AppTextStyles.bodyPrimary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Publishing...',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
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
              WavyProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.outline,
                height: 3,
                amplitude: 5.5,
                wavelength: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
