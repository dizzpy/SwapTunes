import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../data/models/creator_profile_form.dart';
import 'creator_loading_screen.dart';

class CreatorSetup extends StatefulWidget {
  /// Pass existing creator profile data for re-activation pre-fill.
  final CreatorProfileForm? existingProfile;

  const CreatorSetup({super.key, this.existingProfile});

  @override
  State<CreatorSetup> createState() => _CreatorSetupState();
}

class _CreatorSetupState extends State<CreatorSetup> {
  final _roleTitleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _soundcloudCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _spotifyArtistCtrl = TextEditingController();
  final _appleMusicCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();

  late List<String> _selectedSpecs;
  String? _roleError;

  static const _allSpecializations = [
    'Producer',
    'Singer / Vocalist',
    'Songwriter',
    'DJ',
    'Mixing Engineer',
    'Mastering Engineer',
    'Sound Designer',
    'Music Video Director',
    'Beat Maker',
    'Live Performer',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    if (p != null) {
      _roleTitleCtrl.text = p.roleTitle ?? '';
      _locationCtrl.text = p.location ?? '';
      _soundcloudCtrl.text = p.soundcloudUrl ?? '';
      _youtubeCtrl.text = p.youtubeUrl ?? '';
      _spotifyArtistCtrl.text = p.spotifyArtistUrl ?? '';
      _appleMusicCtrl.text = p.appleMusicUrl ?? '';
      _portfolioCtrl.text = p.portfolioUrl ?? '';
      _selectedSpecs = List<String>.from(p.specializations);
    } else {
      _selectedSpecs = [];
    }
  }

  @override
  void dispose() {
    _roleTitleCtrl.dispose();
    _locationCtrl.dispose();
    _soundcloudCtrl.dispose();
    _youtubeCtrl.dispose();
    _spotifyArtistCtrl.dispose();
    _appleMusicCtrl.dispose();
    _portfolioCtrl.dispose();
    super.dispose();
  }

  void _toggleSpec(String spec) {
    setState(() {
      if (_selectedSpecs.contains(spec)) {
        _selectedSpecs.remove(spec);
      } else {
        _selectedSpecs.add(spec);
      }
    });
  }

  void _submit() {
    final roleTitle = _roleTitleCtrl.text.trim();
    setState(() => _roleError = roleTitle.isEmpty ? 'Role title is required' : null);
    if (roleTitle.isEmpty) return;
    if (_selectedSpecs.isEmpty) {
      AppSnackbar.error('Select at least one specialization');
      return;
    }

    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CreatorLoadingScreen(
          formData: CreatorProfileForm(
            roleTitle: roleTitle,
            specializations: _selectedSpecs,
            location: _locationCtrl.text.trim(),
            soundcloudUrl: _soundcloudCtrl.text.trim(),
            youtubeUrl: _youtubeCtrl.text.trim(),
            spotifyArtistUrl: _spotifyArtistCtrl.text.trim(),
            appleMusicUrl: _appleMusicCtrl.text.trim(),
            portfolioUrl: _portfolioCtrl.text.trim(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardFront,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: HugeIcon(
                  icon: AppAssets.icon.arrowLeft,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              AppStrings.creator.creatorSetupTitle,
              style: AppTextStyles.heading3,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(AppStrings.creator.professionalInfoSection),
                const SizedBox(height: 16),
                InputBox(
                  title: AppStrings.creator.roleTitleLabel,
                  hintText: AppStrings.creator.roleTitleHint,
                  controller: _roleTitleCtrl,
                  errorMessage: _roleError,
                ),
                const SizedBox(height: 16),
                InputBox(
                  title: AppStrings.creator.locationLabel,
                  hintText: AppStrings.creator.locationHint,
                  controller: _locationCtrl,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.location,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 32),

                _SectionTitle(AppStrings.creator.specializationSection),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _allSpecializations
                      .map((spec) => _SpecChip(
                            label: spec,
                            isSelected: _selectedSpecs.contains(spec),
                            onTap: () => _toggleSpec(spec),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 32),

                _SectionTitle(AppStrings.creator.portfolioSection),
                const SizedBox(height: 16),
                InputBox(
                  hintText: AppStrings.creator.soundcloudHint,
                  controller: _soundcloudCtrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.link,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                InputBox(
                  hintText: AppStrings.creator.youtubeHint,
                  controller: _youtubeCtrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.link,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                InputBox(
                  hintText: AppStrings.creator.spotifyArtistHint,
                  controller: _spotifyArtistCtrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.link,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                InputBox(
                  hintText: AppStrings.creator.appleMusicHint,
                  controller: _appleMusicCtrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.link,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                InputBox(
                  hintText: AppStrings.creator.portfolioHint,
                  controller: _portfolioCtrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: HugeIcon(
                    icon: AppAssets.icon.externalLink,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 48),

                GreenButton(
                  text: AppStrings.creator.completeSetupBtn,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.bodyPrimary);
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenDarkBg : AppColors.cardFront,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySecondaryWhite.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textWhite,
          ),
        ),
      ),
    );
  }
}
