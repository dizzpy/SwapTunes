import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';

/// DEV-ONLY screen — never ship in production.
///
/// Accessible via long-press on the user's name in OwnProfileScreen.
/// Allows quickly resetting user role for testing the creator setup flow.
class DevToolsScreen extends StatefulWidget {
  final ApiClient apiClient;
  const DevToolsScreen({super.key, required this.apiClient});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  bool _loading = false;
  String? _lastResult;

  Future<void> _resetRole(String role, {bool clearCreatorProfile = false}) async {
    final authVm = context.read<AuthViewmodel>();
    final profileRepo = context.read<ProfileRepository>();
    final username = authVm.currentUser?.username ?? '';
    if (username.isEmpty) {
      AppSnackbar.error('No logged-in user found');
      return;
    }

    setState(() {
      _loading = true;
      _lastResult = null;
    });

    try {
      await widget.apiClient.post(
        ApiConstants.devResetRole,
        body: {
          'username': username,
          'role': role,
          'clear_creator_profile': clearCreatorProfile,
        },
      );

      // Refresh auth + profile
      await authVm.refreshCurrentUser();
      profileRepo.invalidateCache(username);

      setState(() {
        _lastResult =
            'Done! $username → $role${clearCreatorProfile ? ' (creator_profiles cleared)' : ''}';
      });
      AppSnackbar.success('Role reset to $role');
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
      AppSnackbar.error(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username =
        context.watch<AuthViewmodel>().currentUser?.username ?? '...';
    final userType =
        context.watch<AuthViewmodel>().currentUser?.userType ?? '...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Dev Tools', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardFront,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Account', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 8),
                  Text('@$username', style: AppTextStyles.bodyPrimary),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: userType == 'creator'
                              ? AppColors.greenDarkBg
                              : AppColors.cardFront,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: userType == 'creator'
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                        child: Text(
                          userType,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: userType == 'creator'
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Role Reset', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 12),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Column(
                    children: [
                      _DevButton(
                        label: 'Switch to Creator',
                        description: 'Sets user_type = creator (keeps profile data)',
                        color: AppColors.primary,
                        onTap: () => _resetRole('creator'),
                      ),
                      const SizedBox(height: 12),
                      _DevButton(
                        label: 'Switch to Listener',
                        description: 'Sets user_type = listener (keeps creator_profiles)',
                        color: AppColors.textSecondary,
                        onTap: () => _resetRole('listener'),
                      ),
                      const SizedBox(height: 12),
                      _DevButton(
                        label: 'Full Reset → Listener',
                        description:
                            'Sets user_type = listener AND deletes creator_profiles row.\nUse this to test the first-time creator setup flow again.',
                        color: AppColors.danger,
                        onTap: () =>
                            _resetRole('listener', clearCreatorProfile: true),
                      ),
                    ],
                  ),
            if (_lastResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardFront,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  _lastResult!,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DevButton({
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyPrimary.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(description, style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}
