import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../creator/data/models/creator_profile_form.dart';
import '../../../creator/presentation/screens/become_a_creator.dart';
import '../../../creator/presentation/viewmodels/creator_viewmodel.dart';
import '../../data/repositories/profile_repository.dart';
import 'edit_profile_screen.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../widgets/profile_header.dart';
import '../widgets/creator_info_section.dart';
import '../widgets/profile_hashtags.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_content_tabs.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/follows_sheet.dart';
import '../../../../core/network/api_client.dart';
import '../../../dev/presentation/screens/dev_tools_screen.dart';

/// Own profile screen — displayed as the Profile tab in bottom navigation.
class OwnProfileScreen extends StatefulWidget {
  const OwnProfileScreen({super.key});

  @override
  State<OwnProfileScreen> createState() => _OwnProfileScreenState();
}

class _OwnProfileScreenState extends State<OwnProfileScreen> {
  late final UserProfileViewmodel _viewmodel;
  int _selectedTabIndex = 0;
  String? _lastUserType;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _viewmodel = UserProfileViewmodel(context.read<ProfileRepository>());
    final authVm = context.read<AuthViewmodel>();
    final username = authVm.currentUser?.username ?? '';
    _lastUserType = authVm.currentUser?.userType;
    
    // Listen to auth changes
    authVm.addListener(_onAuthChanged);
    
    if (username.isNotEmpty) {
      _viewmodel.loadProfile(username).then((_) => _viewmodel.loadUserPosts());
    }
  }

  void _onAuthChanged() {
    if (!mounted || _isRefreshing) return;
    
    final authVm = context.read<AuthViewmodel>();
    final currentUserType = authVm.currentUser?.userType;
    
    // If user type changed (listener <-> creator), refresh the profile
    if (_lastUserType != null && 
        currentUserType != null && 
        _lastUserType != currentUserType) {
      _lastUserType = currentUserType;
      // Reset tab index to avoid out-of-bounds error when tabs change
      setState(() => _selectedTabIndex = 0);
      final username = authVm.currentUser?.username ?? '';
      if (username.isNotEmpty) {
        _isRefreshing = true;
        _viewmodel.refresh(username).whenComplete(() {
          if (mounted) _isRefreshing = false;
        });
      }
    } else if (_lastUserType == null && currentUserType != null) {
      _lastUserType = currentUserType;
    }
  }

  @override
  void dispose() {
    context.read<AuthViewmodel>().removeListener(_onAuthChanged);
    _viewmodel.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final username = context.read<AuthViewmodel>().currentUser?.username ?? '';
    if (username.isNotEmpty) await _viewmodel.refresh(username);
  }

  Future<void> _switchToListener(BuildContext ctx) async {
    final confirmed = await AppConfirmDialog.show(
      ctx,
      title: 'Switch to Listener?',
      message:
          'Your open collaborations will be closed. Your creator profile data will be saved if you want to switch back later.',
      confirmLabel: 'Switch',
      isDanger: true,
    );
    if (confirmed != true || !mounted) return;

    final creatorVm = context.read<CreatorViewmodel>();
    final authVm = context.read<AuthViewmodel>();
    final profileRepo = context.read<ProfileRepository>();

    final success = await creatorVm.deactivateCreator();
    if (!mounted) return;

    if (success) {
      final username = authVm.currentUser?.username ?? '';
      if (username.isNotEmpty) {
        profileRepo.invalidateCache(username);
      }
      // Auth listener will handle the refresh automatically
      await authVm.refreshCurrentUser();
      if (mounted) {
        AppSnackbar.success('Switched to listener mode');
      }
    } else {
      AppSnackbar.error(creatorVm.errorMessage ?? 'Switch failed. Try again.');
    }
  }

  // ── Image editing ────────────────────────────────────────────────

  Future<void> _onAvatarTap() async {
    final profile = _viewmodel.profile;
    if (profile == null) return;
    await _showImageOptions(
      hasImage: profile.avatarUrl != null,
      onView: () => _viewFullScreen(profile.avatarUrl!),
      onPick: (source) => _pickAndUpload(source, isAvatar: true),
      onDelete: () => _deleteImage(isAvatar: true),
    );
  }

  Future<void> _onCoverTap() async {
    final profile = _viewmodel.profile;
    if (profile == null) return;
    await _showImageOptions(
      hasImage: profile.coverUrl != null,
      onView: () => _viewFullScreen(profile.coverUrl!),
      onPick: (source) => _pickAndUpload(source, isAvatar: false),
      onDelete: () => _deleteImage(isAvatar: false),
    );
  }

  Future<void> _showImageOptions({
    required bool hasImage,
    required VoidCallback onView,
    required void Function(ImageSource) onPick,
    required VoidCallback onDelete,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardFront,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (hasImage)
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textWhite,
                ),
                title: Text('View photo', style: AppTextStyles.bodyPrimary),
                onTap: () {
                  Navigator.pop(ctx);
                  onView();
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Choose from library',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Take a photo',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.camera);
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Remove photo',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.danger,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    ImageSource source, {
    required bool isAvatar,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null || !mounted) return;

    try {
      final repo = context.read<ProfileRepository>();
      final url = await repo.uploadImage(file);
      if (!mounted) return;

      // Capture context-dependent refs before next await
      final authVm = context.read<AuthViewmodel>();
      final profileRepo = context.read<ProfileRepository>();

      // Optimistic UI update
      if (isAvatar) {
        _viewmodel.applyLocalProfileEdit(avatarUrl: url);
        await repo.updateProfile(avatarUrl: url);
      } else {
        _viewmodel.applyLocalProfileEdit(coverUrl: url);
        await repo.updateProfile(coverUrl: url);
      }
      final username = authVm.currentUser?.username ?? '';
      if (username.isNotEmpty) {
        profileRepo.invalidateCache(username);
      }
      AppSnackbar.success('Photo updated');
    } catch (_) {
      AppSnackbar.error('Upload failed. Try again.');
    }
  }

  Future<void> _deleteImage({required bool isAvatar}) async {
    try {
      final repo = context.read<ProfileRepository>();
      if (isAvatar) {
        _viewmodel.applyLocalProfileEdit(avatarUrl: null);
        await repo.updateProfile(avatarUrl: '');
      } else {
        _viewmodel.applyLocalProfileEdit(coverUrl: null);
        await repo.updateProfile(coverUrl: '');
      }
      AppSnackbar.success('Photo removed');
    } catch (_) {
      AppSnackbar.error('Failed to remove photo.');
    }
  }

  void _viewFullScreen(String url) {
    ProfileImageViewer.show(context, url);
  }

  // ── Bio inline edit ──────────────────────────────────────────────

  Future<void> _onBioTap() async {
    final profile = _viewmodel.profile;
    if (profile == null) return;
    final ctrl = TextEditingController(text: profile.bio ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cardFront,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Bio', style: AppTextStyles.bodyPrimary),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 4,
                  maxLength: 200,
                  style: AppTextStyles.bodyPrimary,
                  decoration: InputDecoration(
                    hintText: 'Tell people about yourself',
                    hintStyle: AppTextStyles.bodySecondary70,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Capture text before disposing — the sheet may still hold a reference
    // to the controller during its exit animation.
    final newBio = ctrl.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());

    if (saved == true && mounted) {
      final repo = context.read<ProfileRepository>();
      final username =
          context.read<AuthViewmodel>().currentUser?.username ?? '';
      _viewmodel.applyLocalProfileEdit(bio: newBio);
      try {
        await repo.updateProfile(bio: newBio);
        if (username.isNotEmpty) {
          repo.invalidateCache(username);
        }
        AppSnackbar.success('Bio updated');
      } catch (_) {
        AppSnackbar.error('Failed to save bio.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _viewmodel,
        builder: (context, _) {
          if (_viewmodel.isLoading) return _buildSkeleton();
          if (_viewmodel.errorMessage != null) {
            return _buildError(_viewmodel.errorMessage!);
          }
          final profile = _viewmodel.profile;
          if (profile == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.cardFront,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(bottom: false, child: const SizedBox(height: 16)),

                  // Cover & Avatar (tappable)
                  ProfileCoverHeader(
                    coverUrl: profile.coverUrl,
                    avatarUrl: profile.avatarUrl,
                    isCreatorMode: profile.isCreator,
                    onAvatarTap: _onAvatarTap,
                    onCoverTap: _onCoverTap,
                  ),
                  const SizedBox(height: 64),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: profile.isCreator
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        // Name & Verified (triple-tap opens dev tools)
                        Row(
                          mainAxisAlignment: profile.isCreator
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onDoubleTap: () {},
                              onLongPress: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DevToolsScreen(
                                      apiClient: context.read<ApiClient>(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                profile.fullName,
                                style: AppTextStyles.heading2,
                              ),
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

                        // Bio — tappable to edit inline
                        GestureDetector(
                          onTap: _onBioTap,
                          child: profile.bio != null && profile.bio!.isNotEmpty
                              ? Text(
                                  profile.bio!,
                                  style: AppTextStyles.bodySecondary70,
                                  textAlign: profile.isCreator
                                      ? TextAlign.start
                                      : TextAlign.center,
                                )
                              : Text(
                                  '+ Add a description',
                                  style: AppTextStyles.bodySecondary70.copyWith(
                                    color: AppColors.primary,
                                  ),
                                  textAlign: profile.isCreator
                                      ? TextAlign.start
                                      : TextAlign.center,
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Creator Tags/Links
                        if (profile.isCreator &&
                            profile.creatorProfile != null) ...[
                          CreatorInfoSection(creator: profile.creatorProfile!),
                          const SizedBox(height: 16),
                        ],

                        // Genres as hashtags
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

                        // Edit Profile Button
                        PrimaryButton(
                          text: 'Edit Profile',
                          backgroundColor: AppColors.cardFront,
                          foregroundColor: AppColors.textWhite,
                          borderRadius: 24,
                          height: 48,
                          onPressed: () async {
                            final username =
                                context
                                    .read<AuthViewmodel>()
                                    .currentUser
                                    ?.username ??
                                '';
                            final saved = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(profile: profile),
                              ),
                            );
                            if (saved == true &&
                                username.isNotEmpty &&
                                mounted) {
                              await _viewmodel.refresh(username);
                            }
                          },
                        ),

                        const SizedBox(height: 16),
                        if (!profile.isCreator)
                          TextAppButton(
                            text: 'Switch to Creator Mode',
                            foregroundColor: AppColors.primary,
                            borderRadius: 24,
                            height: 48,
                            onPressed: () async {
                              final existingProfile =
                                  profile.creatorProfile != null
                                      ? CreatorProfileForm.fromCreatorProfile(
                                          profile.creatorProfile!)
                                      : null;
                              final authVm = context.read<AuthViewmodel>();
                              final profileRepo =
                                  context.read<ProfileRepository>();
                              final became = await Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => BecomeACreator(
                                    existingProfile: existingProfile,
                                  ),
                                ),
                              );
                              if (became == true && mounted) {
                                await authVm.refreshCurrentUser();
                                final username =
                                    authVm.currentUser?.username ?? '';
                                if (username.isNotEmpty) {
                                  profileRepo.invalidateCache(username);
                                  await _viewmodel.refresh(username);
                                }
                              }
                            },
                          )
                        else
                          TextAppButton(
                            text: 'Switch to Listener',
                            foregroundColor: AppColors.textSecondary,
                            borderRadius: 24,
                            height: 48,
                            onPressed: () => _switchToListener(context),
                          ),
                        const SizedBox(height: 32),

                        // Tabs
                        ProfileContentTabs(
                          selectedIndex: _selectedTabIndex,
                          isCreatorMode: profile.isCreator,
                          onTabChanged: (index) {
                            setState(() => _selectedTabIndex = index);
                            if (index == 0) _viewmodel.loadUserPosts();
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tab content
                        ProfileTabContent(
                          selectedIndex: _selectedTabIndex,
                          isCreatorMode: profile.isCreator,
                          isOwnProfile: true,
                          posts: _viewmodel.posts,
                          isPostsLoading: _viewmodel.isPostsLoading,
                          onPostDeleted: _viewmodel.removePost,
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.cardFront,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 80),
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
              onPressed: () {
                final username =
                    context.read<AuthViewmodel>().currentUser?.username ?? '';
                if (username.isNotEmpty) _viewmodel.loadProfile(username);
              },
            ),
          ],
        ),
      ),
    );
  }
}
