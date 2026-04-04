import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/models/suggested_user_model.dart';
import '../viewmodels/discover_viewmodel.dart';
import '../widgets/suggest_user_tile.dart';

enum _UserFilter { all, creators, listeners }

class SuggestedUsersScreen extends StatelessWidget {
  final DiscoverViewModel viewModel;

  const SuggestedUsersScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const _SuggestedUsersContent(),
    );
  }
}

class _SuggestedUsersContent extends StatefulWidget {
  const _SuggestedUsersContent();

  @override
  State<_SuggestedUsersContent> createState() => _SuggestedUsersContentState();
}

class _SuggestedUsersContentState extends State<_SuggestedUsersContent> {
  _UserFilter _activeFilter = _UserFilter.all;

  List<SuggestedUserModel> _applyFilter(List<SuggestedUserModel> users) {
    switch (_activeFilter) {
      case _UserFilter.creators:
        return users.where((u) => u.userType == 'creator').toList();
      case _UserFilter.listeners:
        return users.where((u) => u.userType != 'creator').toList();
      case _UserFilter.all:
        return users;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiscoverViewModel>();
    final filtered = _applyFilter(viewModel.suggestedUsers);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textWhite,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Suggested for you', style: AppTextStyles.heading3),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: viewModel.suggestedUsers.length,
                  isSelected: _activeFilter == _UserFilter.all,
                  onTap: () => setState(() => _activeFilter = _UserFilter.all),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Creators',
                  count: viewModel.suggestedUsers
                      .where((u) => u.userType == 'creator')
                      .length,
                  isSelected: _activeFilter == _UserFilter.creators,
                  onTap: () =>
                      setState(() => _activeFilter = _UserFilter.creators),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Listeners',
                  count: viewModel.suggestedUsers
                      .where((u) => u.userType != 'creator')
                      .length,
                  isSelected: _activeFilter == _UserFilter.listeners,
                  onTap: () =>
                      setState(() => _activeFilter = _UserFilter.listeners),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Result count ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${filtered.length} ${filtered.length == 1 ? 'person' : 'people'}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _emptyMessage,
                      style: AppTextStyles.bodySecondaryWhite.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return SuggestUserTile(
                        name: user.fullName,
                        subtitle: _userSubtitle(user),
                        avatarUrl: user.avatarUrl,
                        isFollowing: viewModel.isFollowing(user.id),
                        isLoading: viewModel.isFollowLoading(user.id),
                        onFollow: () => viewModel.toggleFollow(user.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(username: user.username),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String get _emptyMessage {
    switch (_activeFilter) {
      case _UserFilter.creators:
        return 'No creators to suggest';
      case _UserFilter.listeners:
        return 'No listeners to suggest';
      case _UserFilter.all:
        return 'No suggestions available';
    }
  }

  String _userSubtitle(SuggestedUserModel user) {
    if (user.userType == 'creator') return 'Creator';
    if (user.userType == 'listener') return 'Listener';
    return '@${user.username}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardFront,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySecondaryWhite.copyWith(
                color: isSelected ? AppColors.background : AppColors.textWhite,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.background.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.background : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
