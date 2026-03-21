import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../../core/utils/app_haptics.dart';

/// Result returned by [EditContentSheet] when editing a post.
class EditPostResult {
  final String content;
  final XFile? newImage;
  final bool removeImage;

  const EditPostResult({
    required this.content,
    this.newImage,
    this.removeImage = false,
  });
}

/// Bottom sheet for editing post or comment content.
///
/// When [showImageEditor] is true, displays the current image with options
/// to change or remove it. Returns [EditPostResult] for posts, or a plain
/// [String] for comments (when [showImageEditor] is false).
class EditContentSheet extends StatefulWidget {
  final String initialContent;
  final String title;
  final int maxLength;
  final bool showImageEditor;
  final String? initialImageUrl;

  const EditContentSheet({
    super.key,
    required this.initialContent,
    required this.title,
    this.maxLength = 1000,
    this.showImageEditor = false,
    this.initialImageUrl,
  });

  @override
  State<EditContentSheet> createState() => _EditContentSheetState();
}

class _EditContentSheetState extends State<EditContentSheet> {
  late final TextEditingController _controller;
  final ImagePicker _picker = ImagePicker();
  bool _hasChanges = false;

  // Image state
  XFile? _newImage;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final textChanged = _controller.text.trim() != widget.initialContent.trim();
    final imageChanged = _newImage != null || _removeImage;
    final changed = textChanged || imageChanged;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  /// Whether there is a visible image (either existing or newly picked).
  bool get _hasVisibleImage {
    if (_newImage != null) return true;
    if (_removeImage) return false;
    return widget.initialImageUrl != null;
  }

  Future<void> _pickImage() async {
    AppHaptics.buttonTap();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newImage = image;
        _removeImage = false;
      });
      _checkChanges();
    }
  }

  void _onRemoveImage() {
    AppHaptics.buttonTap();
    setState(() {
      _newImage = null;
      _removeImage = true;
    });
    _checkChanges();
  }

  void _save() {
    if (!_hasChanges) return;
    AppHaptics.success();
    if (widget.showImageEditor) {
      Navigator.pop(
        context,
        EditPostResult(
          content: _controller.text.trim(),
          newImage: _newImage,
          removeImage: _removeImage,
        ),
      );
    } else {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: AppTextStyles.bodyPrimary),
              GestureDetector(
                onTap: _hasChanges ? _save : null,
                child: Text(
                  'Save',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: _hasChanges
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Text field
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            maxLines: null,
            minLines: 3,
            autofocus: true,
            style: AppTextStyles.bodyPrimary,
            decoration: InputDecoration(
              hintText: 'Write something...',
              hintStyle: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.cardFront,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              counterStyle: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          // Image editor section
          if (widget.showImageEditor) ...[
            const SizedBox(height: 15),
            if (_hasVisibleImage) _buildImagePreview(),
            if (!_hasVisibleImage) _buildAddImageButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: _newImage != null
                ? Image.file(File(_newImage!.path), fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: widget.initialImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.cardFront,
                      child: const Center(
                        child: WavyCircularIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        // Action buttons on top-right
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _ImageActionButton(
                icon: AppAssets.icon.gallery,
                onTap: _pickImage,
              ),
              const SizedBox(width: 8),
              _ImageActionButton(
                icon: AppAssets.icon.close,
                onTap: _onRemoveImage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Column(
          children: [
            HugeIcon(
              icon: AppAssets.icon.gallery,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Add image',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _ImageActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: Colors.white, size: 18),
      ),
    );
  }
}
