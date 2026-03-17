import 'package:flutter/material.dart';
import 'package:swaptune/features/feed/presentation/widgets/post_card.dart';
import 'package:swaptune/features/feed/presentation/widgets/post_input_box.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/app_icon_button.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: const [
          PostInputBox(),
          SizedBox(height: 24),
          PostCard(
            userName: "honeymoon",
            authorName: "Lana Del Rey",
            isVerified: true,
            avatarUrl:
                'https://i.pinimg.com/736x/d0/f7/85/d0f78534886dae30e4abad239214b999.jpg',
            imageUrl:
                'https://i.pinimg.com/736x/f3/5d/20/f35d206fffdeed6ab33c9a8b0ab4d2d7.jpg',
            caption: 'Inspirational designs, illustrations, and graphic',
            likes: '345K Likes',
            comments: '56K Comment',
            isLiked: true,
            heroTag: 'post_1',
          ),
          SizedBox(height: 16),
          PostCard(
            userName: "Dizzpy Sanchez",
            authorName: "dizzpy",
            isVerified: true,
            avatarUrl: 'https://i.pravatar.cc/150?img=3',
            imageUrl:
                'https://images.unsplash.com/photo-1600868840411-209be2b02a24', // Placeholder
            caption: 'Another cool post down here',
            likes: '12K Likes',
            comments: '3K Comment',
            isLiked: false,
            isOwnPost: true,
            heroTag: 'post_2',
          ),
          SizedBox(height: 80), // To make room for bottom navigation
        ],
      ),
    );
  }
}
