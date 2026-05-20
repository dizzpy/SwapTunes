import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/services/onesignal_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_input_dialog.dart';
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

  // ── Notification preferences ──────────────────────────────────────
  bool _pushNotifications = true;
  bool _activityNotifications = true;
  bool _messageNotifications = true;
  bool _collabNotifications = true;

  // ── App version ────────────────────────────────────────────────────
  String _appVersion = '—';

  // ── Dev Settings local state (mirrors StorageService) ─────────────
  String _devBaseUrl = ApiConstants.baseUrl;
  bool _devGeminiKeySet = false;

  @override
  void initState() {
    super.initState();
    MainLayoutScreen.hideNavBar();
    _loadNotifPrefs();
    _loadAppVersion();
    _loadDevSettings();
  }

  void _loadDevSettings() {
    final storage = context.read<StorageService>();
    setState(() {
      _devBaseUrl = ApiConstants.baseUrl;
      _devGeminiKeySet = (storage.getDevGeminiKey() ?? '').isNotEmpty;
    });
  }

  @override
  void dispose() {
    MainLayoutScreen.showNavBar();
    super.dispose();
  }

  void _loadNotifPrefs() {
    final storage = context.read<StorageService>();
    setState(() {
      _pushNotifications = storage.pushNotificationsEnabled;
      _activityNotifications = storage.activityNotificationsEnabled;
      _messageNotifications = storage.messageNotificationsEnabled;
      _collabNotifications = storage.collabNotificationsEnabled;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  // ── Notification toggles ──────────────────────────────────────────

  Future<void> _onPushToggled(bool value) async {
    setState(() => _pushNotifications = value);
    await context.read<StorageService>().setPushNotificationsEnabled(value);
    if (value) {
      await OnesignalService.optIn();
    } else {
      await OnesignalService.optOut();
    }
  }

  Future<void> _onActivityToggled(bool value) async {
    setState(() => _activityNotifications = value);
    await context.read<StorageService>().setActivityNotificationsEnabled(value);
  }

  Future<void> _onMessageToggled(bool value) async {
    setState(() => _messageNotifications = value);
    await context.read<StorageService>().setMessageNotificationsEnabled(value);
  }

  Future<void> _onCollabToggled(bool value) async {
    setState(() => _collabNotifications = value);
    await context.read<StorageService>().setCollabNotificationsEnabled(value);
  }

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
    if (secondConfirm != true || !mounted) return;

    try {
      await context.read<AuthViewmodel>().deleteAccount();
    } catch (_) {
      if (mounted) AppSnackbar.error(_s.deleteFailed);
    }
  }

  // ── Dev Settings handlers ─────────────────────────────────────────

  Future<void> _onEditBaseUrl() async {
    final storage = context.read<StorageService>();
    final entered = await AppInputDialog.show(
      context,
      title: _s.devBaseUrlDialogTitle,
      message: _s.devBaseUrlDialogMessage,
      initialValue: storage.getDevBaseUrl() ?? ApiConstants.baseUrl,
      hintText: _s.devBaseUrlHint,
      keyboardType: TextInputType.url,
    );
    if (entered == null) return;

    await storage.setDevBaseUrl(entered.isEmpty ? null : entered);
    ApiConstants.setBaseUrlOverride(entered.isEmpty ? null : entered);

    if (!mounted) return;
    setState(() => _devBaseUrl = ApiConstants.baseUrl);
    AppSnackbar.success(
      entered.isEmpty ? _s.devBaseUrlCleared : _s.devBaseUrlSaved,
    );
  }

  Future<void> _onEditGeminiKey() async {
    final storage = context.read<StorageService>();
    final entered = await AppInputDialog.show(
      context,
      title: _s.devGeminiKeyDialogTitle,
      message: _s.devGeminiKeyDialogMessage,
      initialValue: storage.getDevGeminiKey() ?? '',
      hintText: _s.devGeminiKeyHint,
      obscure: true,
    );
    if (entered == null) return;

    await storage.setDevGeminiKey(entered.isEmpty ? null : entered);

    if (!mounted) return;
    setState(() => _devGeminiKeySet = entered.isNotEmpty);
    AppSnackbar.success(
      entered.isEmpty ? _s.devGeminiKeyCleared : _s.devGeminiKeySaved,
    );
  }

  Future<void> _onTestBaseUrl() async {
    final apiClient = context.read<ApiClient>();
    try {
      await apiClient.get(ApiConstants.health);
      if (!mounted) return;
      AppSnackbar.success('${_s.devTestBaseUrlOk} — ${ApiConstants.baseUrl}');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      AppSnackbar.error('${_s.devTestBaseUrlFail}: $msg');
    }
  }

  Future<void> _onTestGeminiKeys() async {
    final apiClient = context.read<ApiClient>();
    try {
      final response = await apiClient.get('/health/ai');
      if (!mounted) return;
      final keys = (response is Map ? response['keys'] : null) as List? ?? [];
      if (keys.isEmpty) {
        AppSnackbar.info(_s.devTestKeysEmpty);
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardFront,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(_s.devTestKeysResultTitle, style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in keys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        (k as Map)['ok'] == true
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: k['ok'] == true
                            ? AppColors.primary
                            : AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${k['label']}'
                          '${k['ok'] == true ? '' : ' — ${k['error'] ?? 'failed'}'}',
                          style: AppTextStyles.bodyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      AppSnackbar.error('${_s.devTestKeysFail}: $msg');
    }
  }

  void _showLicenses() => showLicensePage(
    context: context,
    applicationName: _s.licenseAppName,
    applicationVersion: _appVersion,
  );

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spotifyConnected =
        context.watch<AuthViewmodel>().currentUser?.spotifyConnected ?? false;

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
                value: spotifyConnected
                    ? _s.spotifyConnected
                    : _s.spotifyNotConnected,
                showChevron: false,
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
                onChanged: _onPushToggled,
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.activityHeart,
                title: _s.activityNotifications,
                subtitle: _s.activitySubtitle,
                value: _activityNotifications,
                onChanged: _pushNotifications ? _onActivityToggled : null,
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.messageAlert,
                title: _s.messageNotifications,
                subtitle: _s.messageSubtitle,
                value: _messageNotifications,
                onChanged: _pushNotifications ? _onMessageToggled : null,
              ),
              SettingsToggleTile(
                icon: AppAssets.icon.collabHandshake,
                title: _s.collabNotifications,
                subtitle: _s.collabSubtitle,
                value: _collabNotifications,
                onChanged: _pushNotifications ? _onCollabToggled : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── About ────────────────────────────────────────────────
          SettingsSection(
            title: _s.sectionAbout,
            children: [
              SettingsTile(
                icon: AppAssets.icon.appInfo,
                title: _s.appVersion,
                value: _appVersion,
                showChevron: false,
              ),
              SettingsTile(
                icon: AppAssets.icon.licenses,
                title: _s.licenses,
                onTap: _showLicenses,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Dev Settings ────────────────────────────────────────
          SettingsSection(
            title: _s.sectionDev,
            children: [
              SettingsTile(
                icon: AppAssets.icon.globe,
                title: _s.devBaseUrlTitle,
                subtitle: _devBaseUrl,
                onTap: _onEditBaseUrl,
              ),
              SettingsTile(
                icon: AppAssets.icon.lockPassword,
                title: _s.devGeminiKeyTitle,
                value: _devGeminiKeySet
                    ? _s.devGeminiKeyValueSet
                    : _s.devGeminiKeyValueNotSet,
                onTap: _onEditGeminiKey,
              ),
              SettingsTile(
                icon: AppAssets.icon.check,
                title: _s.devTestBaseUrlTitle,
                subtitle: _s.devTestBaseUrlSubtitle,
                showChevron: false,
                onTap: _onTestBaseUrl,
              ),
              SettingsTile(
                icon: AppAssets.icon.check,
                title: _s.devTestKeysTitle,
                subtitle: _s.devTestKeysSubtitle,
                showChevron: false,
                onTap: _onTestGeminiKeys,
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
