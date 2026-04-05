import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/notification_model.dart';

/// A group of related notifications (same type + same reference).
class NotificationGroup {
  final String type;
  final String? referenceId;
  final List<NotificationModel> items;

  NotificationGroup({
    required this.type,
    this.referenceId,
    required this.items,
  });

  NotificationModel get latest => items.first;
  int get count => items.length;
  bool get isRead => items.every((n) => n.isRead);
  DateTime get createdAt => latest.createdAt;
  List<String> get ids => items.map((n) => n.id).toList();

  /// Key used to decide which notifications belong together.
  static String keyOf(NotificationModel n) {
    switch (n.type) {
      case 'follow':
        return 'follow'; // all follows group together
      default:
        return '${n.type}_${n.referenceId ?? n.id}';
    }
  }

  /// Groups a flat list into [NotificationGroup]s, preserving date order.
  static List<NotificationGroup> from(List<NotificationModel> notifications) {
    final Map<String, NotificationGroup> map = {};
    final List<String> order = [];

    for (final n in notifications) {
      final key = keyOf(n);
      if (map.containsKey(key)) {
        map[key]!.items.add(n);
      } else {
        order.add(key);
        map[key] = NotificationGroup(
          type: n.type,
          referenceId: n.referenceId,
          items: [n],
        );
      }
    }
    return order.map((k) => map[k]!).toList();
  }

  /// Human-readable actor text for this group.
  String get actorText {
    if (count == 1) return '@${latest.actorUsername}';
    if (count == 2) {
      return '@${items[0].actorUsername} and @${items[1].actorUsername}';
    }
    return '@${latest.actorUsername} and ${count - 1} others';
  }

  /// Human-readable action label.
  String get actionLabel {
    switch (type) {
      case 'like':
        return count > 1 ? 'liked your post' : 'liked your post';
      case 'comment':
        return count > 1 ? 'commented on your post' : 'commented on your post';
      case 'follow':
        return count > 1 ? 'started following you' : 'started following you';
      case 'message':
        return 'sent you a message';
      case 'collab':
        return 'is interested in your collab';
      default:
        return 'interacted with you';
    }
  }

  /// Icon for the badge overlay.
  dynamic get badgeIcon {
    switch (type) {
      case 'like':
        return HugeIcons.strokeRoundedFavourite;
      case 'comment':
        return HugeIcons.strokeRoundedComment01;
      case 'follow':
        return HugeIcons.strokeRoundedUserAdd01;
      case 'message':
        return HugeIcons.strokeRoundedMessage01;
      case 'collab':
        return HugeIcons.strokeRoundedUserSharing;
      default:
        return HugeIcons.strokeRoundedNotification01;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationItemWidget extends StatelessWidget {
  final NotificationGroup group;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !group.isRead;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.cardFront,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarWithBadge(
                avatarUrl: group.latest.actorAvatarUrl,
                name: group.latest.actorName,
                badgeIcon: group.badgeIcon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBody(),
                    const SizedBox(height: 3),
                    Text(
                      group.latest.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: group.actorText,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: ' ${group.actionLabel}',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final dynamic badgeIcon;

  const _AvatarWithBadge({
    this.avatarUrl,
    required this.name,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.outline,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _Initials(initials),
                    ),
                  )
                : _Initials(initials),
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Center(
                child: HugeIcon(icon: badgeIcon, color: Colors.white, size: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
}
