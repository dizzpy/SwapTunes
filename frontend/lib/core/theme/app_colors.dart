import 'package:flutter/material.dart';

/// Defines the centralized color palette for the SwapTunes application.
///
/// Contains all static colors matching the Figma design variables.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF191A1A);
  static const Color cardFront = Color(0xFF222424);
  static const Color outline = Color(0xFF434747);

  // Text Colors
  static const Color textWhite = Color(0xFFF3F5F7);
  static const Color textSecondary = Color(0xFFA7A9A9);

  // Primary
  static const Color primary = Color(0xFF10B981);
  static const Color greenDarkBg = Color(0x2610B981); // 15% opacity

  // Others
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFFBBF24);

  // Gradient (40% to 0% opacity)
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x6610B981), // 40% opacity
      Color(0x0010B981), // 0% opacity
    ],
  );
}
