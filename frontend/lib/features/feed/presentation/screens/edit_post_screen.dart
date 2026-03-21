import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../viewmodels/feed_viewmodel.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialContent;
  final String? initialImageUrl;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialContent,
    this.initialImageUrl,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _captionController;
  final ImagePicker _picker = ImagePicker();

  XFile? _newImage;
  bool _removeImage = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialContent);
    _captionController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final textChanged =
        _captionController.text.trim() != widget.initialContent.trim();
    final imageChanged = _newImage != null || _removeImage;
    final changed = textChanged || imageChanged;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  /// Whether there is a visible image (existing, new, or removed).
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
    final feedVm = context.read<FeedViewmodel>();
    feedVm.updatePost(
      widget.postId,
      _captionController.text.trim(),
      newImage: _newImage,
      removeImage: _removeImage,
    );
    Navigator.pop(context);
    AppSnackbar.success('Post updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppAssets.icon.close,
            color: AppColors.textWhite,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Edit post', style: AppTextStyles.heading3),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: TextButton(
              onPressed: _hasChanges ? _save : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    _hasChanges ? AppColors.primary : AppColors.cardFront,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: _hasChanges
                      ? AppColors.background
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _captionController,
                    maxLines: null,
                    maxLength: 1000,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind ?',
                      hintStyle: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      counterStyle: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    autofocus: true,
                  ),
                  if (_hasVisibleImage) ...[
                    const SizedBox(height: 20),
                    _buildImagePreview(),
                  ],
                ],
              ),
            ),
          ),
          // Attachment bar
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              top: 10,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: HugeIcon(
                      icon: AppAssets.icon.gallery,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedMagicWand01,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
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
            height: 250,
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
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _onRemoveImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
