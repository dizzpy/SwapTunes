import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/app_button.dart';

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

  // Selected tab index (0 = Posts, 1 = Collabs, 2 = Songs)
  int _selectedTabIndex = 0;

  // Dev toggle for viewing both modes
  bool _isCreatorMode = true;

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

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
                    // Reset tab to avoid out of bounds in listener mode
                    _selectedTabIndex = 0;
                  });
                },
              ),
            ),

            // Cover & Avatar
            _buildHeader(),
            const SizedBox(height: 64), // Space for avatar overlap
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

                  // Tags/Links
                  if (_isCreatorMode) ...[
                    _buildTags(),
                    const SizedBox(height: 16),
                  ],

                  // Hashtags
                  _buildHashtags(),
                  const SizedBox(height: 24),

                  // Stats Card
                  _buildStatsCard(),
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

                  // Listener extra button
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
                  _buildTabs(),
                  const SizedBox(height: 24),

                  // Content List
                  _buildContentList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: _isCreatorMode ? Alignment.bottomLeft : Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(coverUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: _isCreatorMode
              ? 16
              : null, // Clear left constraint when centering
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardFront,
              border: Border.all(color: AppColors.background, width: 6),
              image: DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Column(
      children: [
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedMusicNote03,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'Producer/Engineer',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'Producer/Engineer',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLink01,
              color: AppColors.primary,
              size: 18.0,
            ),
            const SizedBox(width: 8),
            Text(
              'soundcloud.com/dizzpysanchez',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showLinksBottomSheet(context),
              child: Text('See More', style: AppTextStyles.bodySecondary70),
            ),
          ],
        ),
      ],
    );
  }

  void _showLinksBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardFront,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              _buildLinkItem('SoundCloud', 'soundcloud.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem('Spotify', 'spotify.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem('YouTube', 'youtube.com/dizzpysanchez'),
              const SizedBox(height: 24),
              _buildLinkItem('Apple Music', 'applemusic.com/dizzpysanchez'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return Row(
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedLink01,
          color: AppColors.textWhite,
          size: 24.0,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyPrimary),
            const SizedBox(height: 4),
            Text(url, style: AppTextStyles.bodySecondary70),
          ],
        ),
      ],
    );
  }

  Widget _buildHashtags() {
    final style = _isCreatorMode
        ? AppTextStyles.bodySecondary70
        : AppTextStyles.bodySecondary.copyWith(color: AppColors.primary);

    return Row(
      mainAxisAlignment: _isCreatorMode
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: hashtags.map((tag) {
        return Padding(
          padding: EdgeInsets.only(
            right: _isCreatorMode ? 12.0 : 6.0,
            left: _isCreatorMode ? 0 : 6.0,
          ),
          child: Text(tag, style: style),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(_formatCount(followers), 'Followers'),
          _buildDivider(),
          _buildStatItem(_formatCount(following), 'Following'),
          _buildDivider(),
          _buildStatItem(posts.toString(), 'Posts'),
          _buildDivider(),
          _isCreatorMode
              ? _buildStatItem(collabs.toString(), 'Collabs')
              : _buildStatItem(playlists.toString(), 'Playlists'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyPrimary),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: AppColors.outline);
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTabItem(
          'Posts',
          AppAssets.icon.image,
          _selectedTabIndex == 0,
          () {
            setState(() => _selectedTabIndex = 0);
          },
        ),
        if (_isCreatorMode) ...[
          _buildTabItem(
            'Collabs',
            HugeIcons.strokeRoundedUserGroup,
            _selectedTabIndex == 1,
            () {
              setState(() => _selectedTabIndex = 1);
            },
          ),
          _buildTabItem(
            'Songs',
            AppAssets.icon.music,
            _selectedTabIndex == 2,
            () {
              setState(() => _selectedTabIndex = 2);
            },
          ),
        ] else ...[
          _buildTabItem(
            'Playlists',
            AppAssets.icon.music, // Placeholder icon for Playlists
            _selectedTabIndex ==
                1, // Treat playlists as index 1 in listener mode
            () {
              setState(() => _selectedTabIndex = 1);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTabItem(
    String label,
    dynamic iconData,
    bool isActive,
    VoidCallback onTap,
  ) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData is IconData)
            Icon(iconData, color: color, size: 20)
          else
            HugeIcon(icon: iconData, color: color, size: 20.0),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    Widget content;

    if (_selectedTabIndex == 0) {
      content = const Center(
        key: ValueKey('Posts'),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Posts will appear here',
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    } else if (!_isCreatorMode && _selectedTabIndex == 1) {
      // Listener Playlists tab
      content = const Center(
        key: ValueKey('Playlists'),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Playlists will appear here',
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    } else if (_isCreatorMode && _selectedTabIndex == 2) {
      // Creator Songs tab
      content = const Center(
        key: ValueKey('Songs'),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Songs will appear here',
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    } else {
      // Creator Collabs design (index 1)
      content = Container(
        key: const ValueKey('Collabs'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://picsum.photos/seed/mixing/100/100',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Mixing Engineer',
                    style: AppTextStyles.bodyPrimary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'I need a mixing engine...',
                    style: AppTextStyles.bodySecondary70,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.textWhite,
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: content,
    );
  }
}
