import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../collab/presentation/screens/collab_details_screen.dart';
import '../../../messaging/data/models/chat_conversation_model.dart';
import '../../../messaging/presentation/screens/single_chat_screen.dart';
import '../../data/repositories/profile_repository.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../widgets/profile_header.dart';
import '../widgets/creator_info_section.dart';
import '../widgets/profile_hashtags.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_content_tabs.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/follows_sheet.dart';

/// Public profile screen — pushed via navigation when tapping a user's
/// avatar/username on feed posts, search results, etc.
///
/// Auto-detects own profile by comparing IDs — shows Edit Profile instead
/// of Follow/Message buttons when viewing self.
class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileViewmodel _viewmodel;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewmodel = UserProfileViewmodel(context.read<ProfileRepository>());
    _viewmodel
        .loadProfile(widget.username)
        .then((_) => _viewmodel.loadUserPosts());
  }

  @override
  void dispose() {
    _viewmodel.dispose();
    super.dispose();
  }

  bool _isOwnProfile(String profileId) {
    final myId = context.read<AuthViewmodel>().currentUser?.id;
    return myId != null && myId == profileId;
  }

  void _onMessageTap(String recipientId) {
    final profile = _viewmodel.profile;
    if (profile == null) return;

    // Build a display model immediately from profile data and navigate
    // right away. SingleChatScreen resolves the conversation ID in background.
    final tempConversation = ChatConversationModel(
      id: '',
      participantId: profile.id,
      participantName: profile.fullName,
      participantUsername: profile.username,
      participantAvatarUrl: profile.avatarUrl,
      isOnline: false,
      lastMessage: '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: 0,
    );

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SingleChatScreen(
          conversation: tempConversation,
          recipientId: recipientId,
        ),
      ),
    );
  }

  Future<void> _onFollowTap() async {
    final isFollowing = _viewmodel.profile?.isFollowing ?? false;

    if (isFollowing) {
      // Confirm before unfollowing
      final confirmed = await AppConfirmDialog.show(
        context,
        title: 'Unfollow',
        message:
            'Are you sure you want to unfollow ${_viewmodel.profile?.fullName ?? 'this user'}?',
        confirmLabel: 'Unfollow',
        isDanger: true,
      );
      if (confirmed != true || !mounted) return;
    }

    await _viewmodel.toggleFollow();
    if (!mounted) return;

    final nowFollowing = _viewmodel.profile?.isFollowing ?? false;
    AppSnackbar.success(nowFollowing ? 'Following' : 'Unfollowed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.username, style: const TextStyle(fontSize: 0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: AppIconButton(
              icon: Icons.arrow_back_ios_new,
              variant: AppIconButtonVariant.filled,
              size: 40,
              iconSize: 20,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewmodel,
        builder: (context, _) {
          if (_viewmodel.isLoading) return _buildSkeleton();
          if (_viewmodel.errorMessage != null) {
            return _buildError(_viewmodel.errorMessage!);
          }
          final profile = _viewmodel.profile;
          if (profile == null) return const SizedBox.shrink();

          final isOwn = _isOwnProfile(profile.id);

          return RefreshIndicator(
            onRefresh: () => _viewmodel.refresh(widget.username),
            color: AppColors.primary,
            backgroundColor: AppColors.cardFront,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context).viewPadding.top + kToolbarHeight,
                  ),

                  // Cover & Avatar — tappable for full-screen view
                  ProfileCoverHeader(
                    coverUrl: profile.coverUrl,
                    avatarUrl: profile.avatarUrl,
                    isCreatorMode: profile.isCreator,
                    onAvatarTap: profile.avatarUrl != null
                        ? () => ProfileImageViewer.show(
                            context,
                            profile.avatarUrl!,
                          )
                        : null,
                    onCoverTap: profile.coverUrl != null
                        ? () => ProfileImageViewer.show(
                            context,
                            profile.coverUrl!,
                          )
                        : null,
                  ),
                  const SizedBox(height: 64),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: profile.isCreator
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        // Name & Verified
                        Row(
                          mainAxisAlignment: profile.isCreator
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Text(
                              profile.fullName,
                              style: AppTextStyles.heading2,
                            ),
                            if (profile.isVerified) ...[
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
                          (profile.bio != null && profile.bio!.isNotEmpty)
                              ? profile.bio!
                              : 'No description',
                          style: AppTextStyles.bodySecondary70,
                          textAlign: profile.isCreator
                              ? TextAlign.start
                              : TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Creator Tags/Links
                        if (profile.isCreator &&
                            profile.creatorProfile != null) ...[
                          CreatorInfoSection(creator: profile.creatorProfile!),
                          const SizedBox(height: 16),
                        ],

                        // Genres
                        if (profile.genres.isNotEmpty)
                          ProfileHashtags(
                            hashtags: profile.genres.map((g) => '#$g').toList(),
                            isCreatorMode: profile.isCreator,
                          ),
                        const SizedBox(height: 24),

                        // Stats Card
                        ProfileStatsCard(
                          followers: profile.stats.followers,
                          following: profile.stats.following,
                          posts: profile.stats.posts,
                          collabs: profile.stats.collabs,
                          playlists: profile.stats.playlists,
                          isCreatorMode: profile.isCreator,
                          onFollowersTap: () => FollowsSheet.show(
                            context,
                            userId: profile.id,
                            initialTab: FollowsTab.followers,
                            repository: context.read<ProfileRepository>(),
                          ),
                          onFollowingTap: () => FollowsSheet.show(
                            context,
                            userId: profile.id,
                            initialTab: FollowsTab.following,
                            repository: context.read<ProfileRepository>(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        if (isOwn) ...[
                          PrimaryButton(
                            text: 'Edit Profile',
                            backgroundColor: AppColors.cardFront,
                            foregroundColor: AppColors.textWhite,
                            borderRadius: 24,
                            height: 48,
                            onPressed: () {},
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ListenableBuilder(
                                  listenable: _viewmodel,
                                  builder: (context, _) {
                                    final following =
                                        _viewmodel.profile?.isFollowing ??
                                        false;
                                    return PrimaryButton(
                                      text: following ? 'Following' : 'Follow',
                                      backgroundColor: following
                                          ? AppColors.cardFront
                                          : AppColors.primary,
                                      foregroundColor: AppColors.textWhite,
                                      borderRadius: 24,
                                      height: 48,
                                      onPressed: _viewmodel.isFollowLoading
                                          ? () {}
                                          : _onFollowTap,
                                    );
                                  },
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
                                  onPressed: () => _onMessageTap(profile.id),
                                ),
                              ),
                            ],
                          ),
                          if (profile.isCreator) ...[
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
                        ],

                        const SizedBox(height: 32),

                        // Tabs
                        ProfileContentTabs(
                          selectedIndex: _selectedTabIndex,
                          isCreatorMode: profile.isCreator,
                          onTabChanged: (index) {
                            setState(() => _selectedTabIndex = index);
                            if (index == 0) _viewmodel.loadUserPosts();
                            if (index == 1 && profile.isCreator) {
                              _viewmodel.loadUserCollabs();
                            }
                            if (index == 2 && profile.isCreator) {
                              _viewmodel.loadUserSongs();
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tab content
                        ProfileTabContent(
                          selectedIndex: _selectedTabIndex,
                          isCreatorMode: profile.isCreator,
                          isOwnProfile: isOwn,
                          posts: _viewmodel.posts,
                          isPostsLoading: _viewmodel.isPostsLoading,
                          onPostDeleted: isOwn ? _viewmodel.removePost : null,
                          collabs: _viewmodel.collabs,
                          isCollabsLoading: _viewmodel.isCollabsLoading,
                          songs: _viewmodel.songs,
                          isSongsLoading: _viewmodel.isSongsLoading,
                          onCollabTap: (collab) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CollabDetailsScreen(collabId: collab.id),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).viewPadding.top + kToolbarHeight,
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 64),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    height: 16,
                    width: i == 0 ? 160 : double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardFront,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.bodySecondary70,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Retry',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              borderRadius: 24,
              height: 48,
              onPressed: () => _viewmodel.loadProfile(widget.username),
            ),
          ],
        ),
      ),
    );
  }
}
