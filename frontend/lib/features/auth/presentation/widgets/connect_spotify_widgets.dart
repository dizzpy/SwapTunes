import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class DoubleSpotifyHeader extends StatelessWidget {
  final double iconSize;

  const DoubleSpotifyHeader({super.key, this.iconSize = 88});

  Widget _buildSpotifyIcon() {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.icons.spotifyLogo,
          width: iconSize * 0.6,
          height: iconSize * 0.6,
          colorFilter: const ColorFilter.mode(
            AppColors.background,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSpotifyIcon(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Icon(Icons.add, color: AppColors.textWhite, size: 28),
        ),
        _buildSpotifyIcon(),
      ],
    );
  }
}

class ConnectSpotifyPrivacyInfo extends StatelessWidget {
  const ConnectSpotifyPrivacyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline,
          color: AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.connectSpotify.privacyInfo,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ConnectSpotifyActionBtn extends StatelessWidget {
  final VoidCallback onTap;

  const ConnectSpotifyActionBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppAssets.icons.spotifyLogo,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  AppColors.success,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.connectSpotify.connectBtn,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
