import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class PostLikesSheet extends StatelessWidget {
  const PostLikesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep variables the same as requested
    final List<Map<String, String>> mockLikes = [
      {
        'name': 'Alex Rivera',
        'handle': '@arivera',
        'avatar': 'https://i.pravatar.cc/150?u=1',
      },
      {
        'name': 'Sarah Chen',
        'handle': '@sarah_c',
        'avatar': 'https://i.pravatar.cc/150?u=2',
      },
      {
        'name': 'Marcus Wright',
        'handle': '@mwright',
        'avatar': 'https://i.pravatar.cc/150?u=3',
      },
      {
        'name': 'Elena Gomez',
        'handle': '@elenag',
        'avatar': 'https://i.pravatar.cc/150?u=4',
      },
      {
        'name': 'Jordan Smith',
        'handle': '@jsmith',
        'avatar': 'https://i.pravatar.cc/150?u=5',
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Indicator (Handle)
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

          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Likes', style: AppTextStyles.heading3),
                Text(
                  '${mockLikes.length} people',
                  style: AppTextStyles.bodySecondary70,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.outline, thickness: 1),

          // List Section
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              itemCount: mockLikes.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final user = mockLikes[index];
                return Row(
                  children: [
                    // Avatar with subtle border
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textWhite.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(user['avatar']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name']!, style: AppTextStyles.bodyPrimary),
                          const SizedBox(height: 2),
                          Text(
                            user['handle']!,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    ),

                    // Follow Button - Refined Pill Style
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
