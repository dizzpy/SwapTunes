import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Cover image with overlapping circular avatar.
///
/// Used by both [OwnProfileScreen] and [UserProfileScreen].
/// - [onAvatarTap] / [onCoverTap]: provide callbacks to make them interactive
///   (own profile shows edit options; public profile shows full-screen viewer).
/// - When both callbacks are null the widgets are not wrapped in GestureDetector.
class ProfileCoverHeader extends StatelessWidget {
  final String? coverUrl;
  final String? avatarUrl;
  final bool isCreatorMode;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCoverTap;

  const ProfileCoverHeader({
    super.key,
    required this.coverUrl,
    required this.avatarUrl,
    required this.isCreatorMode,
    this.onAvatarTap,
    this.onCoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment:
          isCreatorMode ? Alignment.bottomLeft : Alignment.bottomCenter,
      children: [
        // Cover image
        _maybeTappable(
          onTap: onCoverTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(18),
              ),
              child: coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        errorWidget: (_, url, err) => const SizedBox.shrink(),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -60,
          left: isCreatorMode ? 16 : null,
          child: _maybeTappable(
            onTap: onAvatarTap,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardFront,
                border: Border.all(color: AppColors.background, width: 6),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorWidget: (_, url, err) => const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _maybeTappable({required Widget child, VoidCallback? onTap}) {
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

/// Full-screen image viewer shown when tapping avatar/cover on a public profile.
class ProfileImageViewer extends StatelessWidget {
  final String imageUrl;

  const ProfileImageViewer({super.key, required this.imageUrl});

  static void show(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => ProfileImageViewer(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              errorWidget: (_, url, err) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
