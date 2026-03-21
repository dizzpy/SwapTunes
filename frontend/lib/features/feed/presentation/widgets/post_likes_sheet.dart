import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/liker_model.dart';
import '../viewmodels/feed_viewmodel.dart';

class PostLikesSheet extends StatefulWidget {
  final String postId;

  const PostLikesSheet({super.key, required this.postId});

  @override
  State<PostLikesSheet> createState() => _PostLikesSheetState();
}

class _PostLikesSheetState extends State<PostLikesSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewmodel>().loadLikers(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = context.watch<FeedViewmodel>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Likes', style: AppTextStyles.heading3),
                Text(
                  feedVm.isLikersLoading
                      ? '...'
                      : '${feedVm.likers.length} people',
                  style: AppTextStyles.bodySecondary70,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.outline, thickness: 1),

          Expanded(
            child: feedVm.isLikersLoading
                ? const Center(
                    child: WavyCircularIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : feedVm.likers.isEmpty
                ? const Center(
                    child: Text(
                      'No likes yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    itemCount: feedVm.likers.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final liker = feedVm.likers[index];
                      return _LikerRow(liker: liker);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LikerRow extends StatelessWidget {
  final LikerModel liker;
  const _LikerRow({required this.liker});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = liker.avatarUrl != null && liker.avatarUrl!.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.08),
              width: 1.5,
            ),
            color: AppColors.outline,
          ),
          child: ClipOval(
            child: hasAvatar
                ? CachedNetworkImage(
                    imageUrl: liker.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(liker.fullName, style: AppTextStyles.bodyPrimary),
              const SizedBox(height: 2),
              Text('@${liker.username}', style: AppTextStyles.bodySecondary),
            ],
          ),
        ),

        SizedBox(
          height: 32,
          width: 85,
          child: OutlinedAppButton(
            text: 'Follow',
            height: 32,
            borderRadius: 20,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
