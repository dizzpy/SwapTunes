import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../feed/presentation/screens/main_layout_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../widgets/notification_item_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  // ── Navigation ────────────────────────────────────────────────────

  void _handleGroupTap(
    BuildContext context,
    NotificationViewmodel vm,
    NotificationGroup group,
  ) {
    HapticFeedback.selectionClick();
    vm.markGroupAsRead(group.ids);

    switch (group.type) {
      case 'follow':
      case 'like':
      case 'comment':
      case 'collab':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                UserProfileScreen(username: group.latest.actorUsername),
          ),
        );

      case 'message':
        Navigator.of(context).pop();
        MainLayoutScreen.switchToInbox();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false, // let list content extend to edge; no nav bar shown here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(vm: vm),
            Expanded(child: _buildBody(context, vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationViewmodel vm) {
    if (vm.isLoading && vm.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      );
    }

    if (vm.error != null && vm.notifications.isEmpty) {
      return _ErrorState(
        message: vm.error!,
        onRetry: () => context.read<NotificationViewmodel>().loadNotifications(),
      );
    }

    if (vm.notifications.isEmpty) {
      return const _EmptyState();
    }

    final groups = NotificationGroup.from(vm.notifications);
    final dateGrouped = _groupByDate(groups);

    return CustomMaterialIndicator(
      onRefresh: () => context.read<NotificationViewmodel>().loadNotifications(),
      backgroundColor: AppColors.cardFront,
      indicatorBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(6),
        child: WavyCircularIndicator(
          size: 36,
          strokeWidth: 3.0,
          color: AppColors.primary,
          waveCount: 14,
          amplitudeFactor: 0.4,
          arcFraction: 1.0,
          showTrack: false,
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _itemCount(dateGrouped) + 1, // +1 for load-more footer
        itemBuilder: (context, index) {
          final totalItems = _itemCount(dateGrouped);
          if (index == totalItems) {
            return _LoadMoreFooter(vm: vm);
          }
          return _buildFlatItem(context, vm, dateGrouped, index);
        },
      ),
    );
  }

  // ── Date grouping ─────────────────────────────────────────────────

  Map<String, List<NotificationGroup>> _groupByDate(
    List<NotificationGroup> groups,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final result = <String, List<NotificationGroup>>{
      'Today': [],
      'This week': [],
      'Earlier': [],
    };

    for (final g in groups) {
      final d = DateTime(g.createdAt.year, g.createdAt.month, g.createdAt.day);
      if (!d.isBefore(today)) {
        result['Today']!.add(g);
      } else if (!d.isBefore(weekAgo)) {
        result['This week']!.add(g);
      } else {
        result['Earlier']!.add(g);
      }
    }

    result.removeWhere((_, v) => v.isEmpty);
    return result;
  }

  int _itemCount(Map<String, List<NotificationGroup>> dateGrouped) {
    int count = 0;
    for (final entry in dateGrouped.entries) {
      count += 1 + entry.value.length;
    }
    return count;
  }

  Widget _buildFlatItem(
    BuildContext context,
    NotificationViewmodel vm,
    Map<String, List<NotificationGroup>> dateGrouped,
    int index,
  ) {
    int cursor = 0;
    for (final entry in dateGrouped.entries) {
      if (index == cursor) return _SectionHeader(title: entry.key);
      cursor++;
      final i = index - cursor;
      if (i < entry.value.length) {
        final group = entry.value[i];
        return _SwipeableNotification(
          group: group,
          onTap: () => _handleGroupTap(context, vm, group),
          onMarkRead: () => vm.markGroupAsRead(group.ids),
          onDelete: () => vm.deleteNotification(group.ids),
        );
      }
      cursor += entry.value.length;
    }
    return const SizedBox.shrink();
  }
}

// ── Swipeable wrapper ─────────────────────────────────────────────────────────

class _SwipeableNotification extends StatelessWidget {
  final NotificationGroup group;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _SwipeableNotification({
    required this.group,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('notif_${group.ids.first}'),
      direction: DismissDirection.horizontal,
      // Swipe right → mark as read (bounces back)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.done_rounded, color: AppColors.primary, size: 22),
      ),
      // Swipe left → delete (removes item)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.selectionClick();
          onMarkRead();
          return false; // bounce back; item stays, just loses unread state
        }
        HapticFeedback.mediumImpact();
        return true; // delete
      },
      onDismissed: (_) => onDelete(),
      child: NotificationItemWidget(group: group, onTap: onTap),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final NotificationViewmodel vm;
  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title — perfectly centered in full width
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications',
                style: AppTextStyles.heading2.copyWith(fontSize: 22),
              ),
              if (vm.unreadCount > 0)
                Text(
                  '${vm.unreadCount} unread',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Buttons row — sits on top but doesn't affect title centering
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardFront,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textWhite,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              if (vm.unreadCount > 0)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<NotificationViewmodel>().markAllAsRead();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.greenDarkBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final NotificationViewmodel vm;
  const _LoadMoreFooter({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (!vm.hasMore) return const SizedBox.shrink();

    if (vm.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.read<NotificationViewmodel>().loadMore();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            'Load more',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.cardFront,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: AppTextStyles.bodyPrimary.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No notifications yet.\nWe'll let you know when something happens.",
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.greenDarkBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Retry',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
