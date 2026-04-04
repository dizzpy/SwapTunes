import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../feed/presentation/screens/main_layout_screen.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _s = AppStrings.settings;

  @override
  void initState() {
    super.initState();
    MainLayoutScreen.hideNavBar();
  }

  @override
  void dispose() {
    MainLayoutScreen.showNavBar();
    super.dispose();
  }

  // ── Local UI state (no ViewModel until backend is wired) ─────────
  bool _pushNotifications = true;
  bool _activityNotifications = true;
  bool _messageNotifications = true;
  bool _collabNotifications = true;
  bool _privateAccount = false;
  bool _hideLikedPosts = false;

  String _selectedTheme = AppStrings.settings.themeSystem;
  String _selectedLanguage = 'English';

  // ── Actions ───────────────────────────────────────────────────────

  Future<void> _onLogout() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: _s.logoutTitle,
      message: _s.logoutMessage,
      confirmLabel: _s.logoutConfirm,
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      await context.read<AuthViewmodel>().logout();
    }
  }

  Future<void> _onDeleteAccount() async {
    final firstConfirm = await AppConfirmDialog.show(
      context,
      title: _s.deleteTitle,
      message: _s.deleteMessage,
      confirmLabel: _s.deleteConfirm,
      isDanger: true,
    );
    if (firstConfirm != true || !mounted) return;

    final secondConfirm = await AppConfirmDialog.show(
      context,
      title: _s.deleteFinalTitle,
      message: _s.deleteFinalMessage,
      confirmLabel: _s.deleteFinalConfirm,
      cancelLabel: _s.cancel,
      isDanger: true,
    );
    if (secondConfirm == true && mounted) {
      // TODO: wire up delete account API call
      AppSnackbar.error(_s.deleteNotAvailable);
    }
  }

  void _showComingSoon(String feature) =>
      AppSnackbar.info(feature + _s.comingSoon);

  // ── Pickers ───────────────────────────────────────────────────────

  void _showThemePicker() => _showOptionSheet(
    title: _s.themePickerTitle,
    options: [_s.themeLight, _s.themeDark, _s.themeSystem],
    selected: _selectedTheme,
    onSelect: (v) => setState(() => _selectedTheme = v),
  );

  void _showLanguagePicker() => _showOptionSheet(
    title: _s.languagePickerTitle,
    options: _s.languages,
    selected: _selectedLanguage,
    onSelect: (v) => setState(() => _selectedLanguage = v),
  );

  void _showDmPrivacyPicker() => _showOptionSheet(
    title: _s.dmPickerTitle,
    options: [_s.dmEveryone, _s.dmFollowersOnly, _s.dmNoOne],
    selected: _s.dmEveryone,
    onSelect: (_) {},
  );

  void _showPlaylistPrivacyPicker() => _showOptionSheet(
    title: _s.playlistPickerTitle,
    options: [_s.playlistPublic, _s.playlistFollowers, _s.playlistPrivate],
    selected: _s.playlistPublic,
    onSelect: (_) {},
  );

  void _showOptionSheet({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.cardFront,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(title, style: AppTextStyles.heading3),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt, style: AppTextStyles.bodyPrimary),
                trailing: opt == selected
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppAssets.icon.arrowLeft,
            color: AppColors.textWhite,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_s.title, style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          // ── Account ─────────────────────────────────────────────
          SettingsSection(
            title: _s.sectionAccount,
            children: [
              SettingsTile(
                icon: AppAssets.icon.spotify,
                iconColor: AppColors.success,
                title: _s.spotifyTitle,
                value: _s.spotifyValue,
                onTap: () => _showComingSoon(_s.spotifyTitle),
              ),
              SettingsTile(
                icon: AppAssets.icon.google,
                iconColor: Colors.blue,
                title: _s.googleTitle,
                value: _s.googleValue,
                onTap: () => _showComingSoon(_s.googleTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Creator Mode ─────────────────────────────────────────
          SettingsSection(
            title: _s.sectionCreator,
            children: [
              SettingsTile(
                icon: AppAssets.icon.starCreator,
                iconColor: AppColors.warning,
                title: _s.creatorProfile,
                subtitle: _s.creatorProfileSubtitle,
                onTap: () => _showComingSoon(_s.creatorProfile),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Notifications ────────────────────────────────────────
          SettingsSection(
            title: _s.sectionNotifications,
            children: [
              SettingsToggleTile(
                icon: AppAssets.icon.bellNotification,
                title: _s.pushNotifications,
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.activityHeart,
                title: _s.activityNotifications,
                subtitle: _s.activitySubtitle,
                value: _activityNotifications,
                onChanged: _pushNotifications
                    ? (v) => setState(() => _activityNotifications = v)
                    : null,
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.messageAlert,
                title: _s.messageNotifications,
                subtitle: _s.messageSubtitle,
                value: _messageNotifications,
                onChanged: _pushNotifications
                    ? (v) => setState(() => _messageNotifications = v)
                    : null,
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.collabHandshake,
                title: _s.collabNotifications,
                subtitle: _s.collabSubtitle,
                value: _collabNotifications,
                onChanged: _pushNotifications
                    ? (v) => setState(() => _collabNotifications = v)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Privacy & Safety ─────────────────────────────────────
          SettingsSection(
            title: _s.sectionPrivacy,
            children: [
              SettingsToggleTile(
                icon: AppAssets.icon.privateEye,
                title: _s.privateAccount,
                subtitle: _s.privateAccountSubtitle,
                value: _privateAccount,
                onChanged: (v) => setState(() => _privateAccount = v),
              ),
              SettingsTile(
                icon: AppAssets.icon.dmLock,
                title: _s.whoCanDm,
                value: _s.whoCanDmDefault,
                onTap: _showDmPrivacyPicker,
              ),
              SettingsTile(
                icon: AppAssets.icon.blockedUser,
                title: _s.blockedUsers,
                onTap: () => _showComingSoon(_s.blockedUsers),
              ),
              SettingsTile(
                icon: AppAssets.icon.mutedUser,
                title: _s.mutedUsers,
                onTap: () => _showComingSoon(_s.mutedUsers),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Music & Content ──────────────────────────────────────
          SettingsSection(
            title: _s.sectionMusic,
            children: [
              SettingsTile(
                icon: AppAssets.icon.playlist,
                title: _s.playlistSharing,
                value: _s.playlistSharingDefault,
                onTap: _showPlaylistPrivacyPicker,
              ),
              SettingsTile(
                icon: AppAssets.icon.genreFilter,
                title: _s.genrePreferences,
                subtitle: _s.genrePreferencesSubtitle,
                onTap: () => _showComingSoon(_s.genrePreferences),
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.hideLike,
                title: _s.hideLikedPosts,
                subtitle: _s.hideLikedPostsSubtitle,
                value: _hideLikedPosts,
                onChanged: (v) => setState(() => _hideLikedPosts = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Appearance ───────────────────────────────────────────
          SettingsSection(
            title: _s.sectionAppearance,
            children: [
              SettingsTile(
                icon: AppAssets.icon.themeMoon,
                title: _s.theme,
                value: _selectedTheme,
                onTap: _showThemePicker,
              ),
              SettingsTile(
                icon: AppAssets.icon.language,
                title: _s.language,
                value: _selectedLanguage,
                onTap: _showLanguagePicker,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── About & Legal ────────────────────────────────────────
          SettingsSection(
            title: _s.sectionAbout,
            children: [
              SettingsTile(
                icon: AppAssets.icon.appInfo,
                title: _s.appVersion,
                value: _s.appVersionValue,
                showChevron: false,
              ),
              SettingsTile(
                icon: AppAssets.icon.terms,
                title: _s.termsOfService,
                onTap: () => _showComingSoon(_s.termsOfService),
              ),
              SettingsTile(
                icon: AppAssets.icon.privacyShield,
                title: _s.privacyPolicy,
                onTap: () => _showComingSoon(_s.privacyPolicy),
              ),
              SettingsTile(
                icon: AppAssets.icon.licenses,
                title: _s.licenses,
                onTap: () => _showComingSoon(_s.licenses),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Danger Zone ──────────────────────────────────────────
          SettingsSection(
            title: _s.sectionDanger,
            children: [
              SettingsTile(
                icon: AppAssets.icon.logout,
                title: _s.logout,
                isDanger: true,
                showChevron: false,
                onTap: _onLogout,
              ),
              SettingsTile(
                icon: AppAssets.icon.deleteAccount,
                title: _s.deleteAccount,
                subtitle: _s.deleteAccountSubtitle,
                isDanger: true,
                showChevron: false,
                onTap: _onDeleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
