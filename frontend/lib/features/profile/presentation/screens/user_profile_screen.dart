import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/app_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/creator_info_section.dart';
import '../widgets/profile_hashtags.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_content_tabs.dart';
import '../widgets/profile_tab_content.dart';

/// Public profile screen — pushed via navigation when tapping a user's
/// avatar/username on feed posts, search results, etc.
///
/// Shows another user's profile with Follow/Unfollow button.
/// Conditionally renders creator sections based on user_type.
class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Pre-defined dummy variables
  final String coverUrl = 'https://picsum.photos/seed/cover4/800/400';
  final String avatarUrl = 'https://picsum.photos/seed/avatar6/200/200';
  final String name = 'Dizzpy Sanchez';
  final bool isVerified = true;
  final String bio =
      'A Zsh plugin that adds convenient aliases for common Flutter commands.';
  final List<String> hashtags = ['#dubstep', '#techno', '#trap'];
  final int followers = 234000;
  final int following = 634000;
  final int posts = 23;
  final int collabs = 12;
  final int playlists = 12;

  int _selectedTabIndex = 0;

  // Dev toggle for viewing both modes
  bool _isCreatorMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.username, style: const TextStyle(fontSize: 0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textWhite,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DEV ONLY: Role Toggle
            SafeArea(
              bottom: false,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text(
                  'Dev View: Creator Mode',
                  style: AppTextStyles.bodySecondaryWhite,
                ),
                activeThumbColor: AppColors.primary,
                value: _isCreatorMode,
                onChanged: (val) {
                  setState(() {
                    _isCreatorMode = val;
                    _selectedTabIndex = 0;
                  });
                },
              ),
            ),

            // Cover & Avatar
            ProfileCoverHeader(
              coverUrl: coverUrl,
              avatarUrl: avatarUrl,
              isCreatorMode: _isCreatorMode,
            ),
            const SizedBox(height: 64),

            // Info content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: _isCreatorMode
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  // Name & Verified
                  Row(
                    mainAxisAlignment: _isCreatorMode
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Text(name, style: AppTextStyles.heading2),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        Icon(
                          AppAssets.icon.verified,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: AppTextStyles.bodySecondary70,
                    textAlign: _isCreatorMode
                        ? TextAlign.start
                        : TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Creator Tags/Links
                  if (_isCreatorMode) ...[
                    const CreatorInfoSection(),
                    const SizedBox(height: 16),
                  ],

                  // Hashtags
                  ProfileHashtags(
                    hashtags: hashtags,
                    isCreatorMode: _isCreatorMode,
                  ),
                  const SizedBox(height: 24),

                  // Stats Card
                  ProfileStatsCard(
                    followers: followers,
                    following: following,
                    posts: posts,
                    collabs: collabs,
                    playlists: playlists,
                    isCreatorMode: _isCreatorMode,
                  ),
                  const SizedBox(height: 24),

                  // Follow and Message Buttons
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Follow',
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          borderRadius: 24,
                          height: 48,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Message',
                          backgroundColor: AppColors.cardFront,
                          foregroundColor: AppColors.textWhite,
                          borderRadius: 24,
                          height: 48,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  // Collaborate Button for Creators
                  if (_isCreatorMode) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Collaborate',
                      backgroundColor: AppColors.cardFront,
                      foregroundColor: AppColors.primary,
                      borderRadius: 24,
                      height: 48,
                      onPressed: () {},
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Tabs
                  ProfileContentTabs(
                    selectedIndex: _selectedTabIndex,
                    isCreatorMode: _isCreatorMode,
                    onTabChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Content
                  ProfileTabContent(
                    selectedIndex: _selectedTabIndex,
                    isCreatorMode: _isCreatorMode,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
