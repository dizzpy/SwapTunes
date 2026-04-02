import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/collab_model.dart';

/// A card widget for displaying a collaboration post in a list.
///
/// Accepts a [CollabModel] directly. Like state is not tracked here since
/// the backend has no like endpoint for collaborations.
class CollabPostCard extends StatelessWidget {
  final CollabModel collab;
  final VoidCallback? onTap;

  /// Optional row of action buttons rendered at the bottom (e.g. Edit/Delete).
  final Widget? actionsRow;

  /// Whether to show the author header (name, avatar, time). Hide for own posts
  /// where the context is already clear.
  final bool showAuthorHeader;

  const CollabPostCard({
    super.key,
    required this.collab,
    this.onTap,
    this.actionsRow,
    this.showAuthorHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAuthorHeader) ...[
              _AuthorHeader(collab: collab),
              const SizedBox(height: 16),
            ],
            _RoleBadge(role: collab.creatorUsername),
            const SizedBox(height: 8),
            Text(
              collab.title,
              style: AppTextStyles.heading3,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!showAuthorHeader) ...[
              const SizedBox(height: 6),
              Text(collab.timeAgo, style: AppTextStyles.bodySecondary),
            ],
            if (collab.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                collab.description,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (collab.lookingFor.isNotEmpty) ...[
              const SizedBox(height: 14),
              _TagsRow(tags: collab.lookingFor),
            ],
            if (actionsRow != null) ...[
              const SizedBox(height: 16),
              actionsRow!,
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  final CollabModel collab;

  const _AuthorHeader({required this.collab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(imageUrl: collab.creatorAvatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collab.creatorFullName,
                style: AppTextStyles.bodyPrimary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(collab.timeAgo, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;

  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.skeletonBase,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const ColoredBox(color: AppColors.skeletonBase),
            errorWidget: (_, _, _) => const Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.skeletonBase,
      child: Icon(Icons.person, color: AppColors.textSecondary, size: 20),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: AppTextStyles.bodySecondary.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;

  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Text(
              '#$tag',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(),
    );
  }
}
