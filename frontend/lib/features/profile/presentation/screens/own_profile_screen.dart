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

/// Own profile screen — displayed as the Profile tab in bottom navigation.
///
/// Shows the current user's profile with stats, genres, and
/// conditionally renders creator-specific sections based on user_type.
class OwnProfileScreen extends StatefulWidget {
  const OwnProfileScreen({super.key});

  @override
  State<OwnProfileScreen> createState() => _OwnProfileScreenState();
}

class _OwnProfileScreenState extends State<OwnProfileScreen> {
  // Pre-defined dummy variables
  final String coverUrl = 'https://picsum.photos/seed/cover3/800/400';
  final String avatarUrl = 'https://picsum.photos/seed/avatar5/200/200';
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
                    textAlign:
                        _isCreatorMode ? TextAlign.start : TextAlign.center,
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

                  // Edit Profile Button
                  PrimaryButton(
                    text: 'Edit Profile',
                    backgroundColor: AppColors.cardFront,
                    foregroundColor: AppColors.textWhite,
                    borderRadius: 24,
                    height: 48,
                    onPressed: () {},
                  ),

                  // Listener: Switch to Creator Mode
                  if (!_isCreatorMode) ...[
                    const SizedBox(height: 16),
                    TextAppButton(
                      text: 'Switch to Creator Mode',
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
