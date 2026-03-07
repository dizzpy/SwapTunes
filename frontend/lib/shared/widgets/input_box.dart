import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class InputBox extends StatelessWidget {
  final String? title;
  final String hintText;
  final bool isMultiLine;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? characterCountText;
  final String? successMessage;
  final String? errorMessage;
  final String? warningMessage;
  final TextEditingController? controller;

  const InputBox({
    super.key,
    this.title,
    required this.hintText,
    this.isMultiLine = false,
    this.obscureText = false,
    this.prefixIcon,
    this.characterCountText,
    this.successMessage,
    this.errorMessage,
    this.warningMessage,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title Label
        if (title != null) ...[
          Text(
            title!,
            // Using a slightly brighter color for the label than the hint text
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. The Text Field (Relies entirely on AppTheme for styling)
        TextField(
          controller: controller,
          obscureText: obscureText,
          // Defines the height behavior for the Bio field
          minLines: isMultiLine ? 4 : 1,
          maxLines: isMultiLine ? 5 : 1,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textWhite,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 10.0),
                    child: prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),

        // 3. Status Messages & Character Count Row
        if (successMessage != null ||
            errorMessage != null ||
            warningMessage != null ||
            characterCountText != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Messages (Left aligned)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (successMessage != null)
                      Text(
                        successMessage!,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    if (warningMessage != null)
                      Text(
                        warningMessage!,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
              // Character Count (Right aligned)
              if (characterCountText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    characterCountText!,
                    style: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
