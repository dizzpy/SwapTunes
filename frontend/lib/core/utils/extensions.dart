import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Convenience extensions on [BuildContext].
extension BuildContextExtensions on BuildContext {
  /// Shortcut to access the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Shortcut to access the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shortcut to access the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shortcut to the current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width shortcut.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height shortcut.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Shows a simple SnackBar with a message.
  void showSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows an error SnackBar with red background.
  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }
}

/// String utility extensions.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncates the string to [maxLength] and appends '...' if needed.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
