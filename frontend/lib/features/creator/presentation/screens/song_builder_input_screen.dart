import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../core/constants/app_assets.dart';
import '../viewmodels/song_builder_viewmodel.dart';
import 'song_builder_loading_screen.dart';

const _kGenres = [
  'Hip Hop',
  'R&B',
  'Pop',
  'Rock',
  'EDM',
  'Electronic',
  'Trap',
  'Afrobeats',
  'Amapiano',
  'Jazz',
  'Classical',
  'Reggae',
  'Dancehall',
  'Sinhala Pop',
  'Sinhala Baila',
  'Other',
];

class SongBuilderInputScreen extends StatefulWidget {
  const SongBuilderInputScreen({super.key});

  @override
  State<SongBuilderInputScreen> createState() => _SongBuilderInputScreenState();
}

class _SongBuilderInputScreenState extends State<SongBuilderInputScreen> {
  final TextEditingController _ideaCtrl = TextEditingController();
  final TextEditingController _lyricsCtrl = TextEditingController();
  String? _selectedGenre;
  String _type = 'vocal'; // 'vocal' | 'instrumental'

  bool get _canBuild =>
      _ideaCtrl.text.trim().length >= 5 && _selectedGenre != null;

  @override
  void initState() {
    super.initState();
    _ideaCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _lyricsCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBuild() async {
    final vm = context.read<SongBuilderViewModel>();
    vm.build(
      idea: _ideaCtrl.text.trim(),
      genre: _selectedGenre!,
      lyrics: _lyricsCtrl.text.trim().isNotEmpty ? _lyricsCtrl.text.trim() : null,
      type: _type,
    );
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const SongBuilderLoadingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppIconButton(
              icon: AppAssets.icon.arrowLeft,
              onTap: () => Navigator.pop(context),
              variant: AppIconButtonVariant.filled,
            ),
          ),
        ),
        title: Text(
          AppStrings.songBuilder.inputTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ── Header banner ──
                _HeaderBanner(),
                const SizedBox(height: 24),

                // ── Idea ──
                _SectionLabel(label: AppStrings.songBuilder.ideaSection),
                const SizedBox(height: 10),
                TextField(
                  controller: _ideaCtrl,
                  style: AppTextStyles.bodyPrimary,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 300,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(
                    hint: AppStrings.songBuilder.ideaHint,
                    counter: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.songBuilder.ideaNote,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Genre ──
                _SectionLabel(label: AppStrings.songBuilder.genreSection),
                const SizedBox(height: 10),
                _GenreDropdown(
                  selected: _selectedGenre,
                  onChanged: (v) => setState(() => _selectedGenre = v),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.songBuilder.genreNote,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Lyrics (optional) ──
                _SectionLabel(label: AppStrings.songBuilder.lyricsSection),
                const SizedBox(height: 10),
                TextField(
                  controller: _lyricsCtrl,
                  style: AppTextStyles.bodyPrimary,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(
                    hint: AppStrings.songBuilder.lyricsHint,
                    counter: true,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Type toggle ──
                _SectionLabel(label: AppStrings.songBuilder.typeSection),
                const SizedBox(height: 10),
                _TypeToggle(
                  selected: _type,
                  onSelect: (t) => setState(() => _type = t),
                ),
              ],
            ),
          ),
          _BottomBar(canBuild: _canBuild, onBuild: _onBuild),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, bool counter = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySecondary.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: AppColors.cardFront,
      counterStyle: AppTextStyles.bodySecondary.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.4),
        fontSize: 11,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER BANNER
// ─────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAiMagic,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.songBuilder.bannerTitle,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.songBuilder.bannerSubtitle,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyPrimary.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

// ─────────────────────────────────────────────
//  GENRE DROPDOWN
// ─────────────────────────────────────────────

class _GenreDropdown extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _GenreDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              AppStrings.songBuilder.genreHint,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
          isExpanded: true,
          dropdownColor: AppColors.cardFront,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          style: AppTextStyles.bodyPrimary,
          icon: const Padding(
            padding: EdgeInsets.only(right: 14),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          items: _kGenres
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TYPE TOGGLE
// ─────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _TypeToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TypeButton(value: 'vocal', label: '🎤  Vocal', selected: selected, onSelect: onSelect)),
        const SizedBox(width: 10),
        Expanded(child: _TypeButton(value: 'instrumental', label: '🎹  Instrumental', selected: selected, onSelect: onSelect)),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String value;
  final String label;
  final String selected;
  final ValueChanged<String> onSelect;

  const _TypeButton({
    required this.value,
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardFront,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyPrimary.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM BAR
// ─────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool canBuild;
  final VoidCallback onBuild;

  const _BottomBar({required this.canBuild, required this.onBuild});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: IgnorePointer(
        ignoring: !canBuild,
        child: AnimatedOpacity(
          opacity: canBuild ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: GreenButton(
            text: AppStrings.songBuilder.buildButton,
            height: 52,
            onPressed: onBuild,
          ),
        ),
      ),
    );
  }
}
