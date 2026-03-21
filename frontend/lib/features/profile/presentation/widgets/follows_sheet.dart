import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../data/models/follow_user_model.dart';
import '../../data/repositories/profile_repository.dart';

enum FollowsTab { followers, following }

/// Single bottom sheet with Followers / Following tabs.
///
/// Opens pre-selected on the tab passed via [initialTab].
/// Each tab fetches lazily when first switched to.
class FollowsSheet extends StatefulWidget {
  final String userId;
  final FollowsTab initialTab;
  final ProfileRepository repository;

  const FollowsSheet({
    super.key,
    required this.userId,
    required this.initialTab,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required FollowsTab initialTab,
    required ProfileRepository repository,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardFront,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FollowsSheet(
        userId: userId,
        initialTab: initialTab,
        repository: repository,
      ),
    );
  }

  @override
  State<FollowsSheet> createState() => _FollowsSheetState();
}

class _FollowsSheetState extends State<FollowsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<FollowUserModel>? _followers;
  List<FollowUserModel>? _following;
  bool _loadingFollowers = false;
  bool _loadingFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == FollowsTab.followers ? 0 : 1,
    );
    _tabController.addListener(_onTabChanged);
    // Load initial tab
    if (widget.initialTab == FollowsTab.followers) {
      _loadFollowers();
    } else {
      _loadFollowing();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0 && _followers == null) {
      _loadFollowers();
    } else if (_tabController.index == 1 && _following == null) {
      _loadFollowing();
    }
  }

  Future<void> _loadFollowers() async {
    if (_loadingFollowers) return;
    setState(() => _loadingFollowers = true);
    try {
      final result = await widget.repository.getFollowers(widget.userId);
      if (mounted) setState(() => _followers = result);
    } catch (_) {
      if (mounted) setState(() => _followers = []);
    } finally {
      if (mounted) setState(() => _loadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    if (_loadingFollowing) return;
    setState(() => _loadingFollowing = true);
    try {
      final result = await widget.repository.getFollowing(widget.userId);
      if (mounted) setState(() => _following = result);
    } catch (_) {
      if (mounted) setState(() => _following = []);
    } finally {
      if (mounted) setState(() => _loadingFollowing = false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.bodyPrimary,
              unselectedLabelStyle: AppTextStyles.bodySecondary70,
              tabs: const [
                Tab(text: 'Followers'),
                Tab(text: 'Following'),
              ],
            ),
            const Divider(color: AppColors.outline, height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(
                    items: _followers,
                    isLoading: _loadingFollowers,
                    emptyMessage: 'No followers yet',
                    scrollController: scrollController,
                  ),
                  _buildList(
                    items: _following,
                    isLoading: _loadingFollowing,
                    emptyMessage: 'Not following anyone yet',
                    scrollController: scrollController,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList({
    required List<FollowUserModel>? items,
    required bool isLoading,
    required String emptyMessage,
    required ScrollController scrollController,
  }) {
    if (isLoading || items == null) {
      return const Center(
        child: WavyCircularIndicator(color: AppColors.primary),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: AppTextStyles.bodySecondary70),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, i) =>
          const Divider(color: AppColors.outline, height: 1),
      itemBuilder: (context, i) => _UserTile(user: items[i]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final FollowUserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.outline,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 22,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: AppTextStyles.bodyPrimary),
              Text('@${user.username}', style: AppTextStyles.bodySecondary70),
            ],
          ),
        ],
      ),
    );
  }
}
