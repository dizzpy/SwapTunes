import 'package:flutter/services.dart';

/// Centralised haptic feedback utility for SwapTunes.
///
/// Provides semantic, named methods instead of raw [HapticFeedback] calls
/// so every callsite communicates intent rather than intensity.
///
/// Usage:
///   AppHaptics.buttonTap();
///   AppHaptics.success();
///   AppHaptics.error();
class AppHaptics {
  AppHaptics._();

  // ── Basic UI Feedback ───────────────────────────────

  /// Very subtle tick — tabs, small UI interactions.
  static void selection() => HapticFeedback.selectionClick();

  /// Soft press — light button taps.
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact — success actions, confirmations.
  static void medium() => HapticFeedback.mediumImpact();

  /// Strong impact — errors, destructive actions.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Default system vibration — alerts.
  static void vibrate() => HapticFeedback.vibrate();

  // ── Predefined UX Patterns ──────────────────────────

  /// Normal button tap.
  static void buttonTap() => light();

  /// Small UI interactions (tabs, switches, toggles).
  static void uiTap() => selection();

  /// Success actions (save, publish, complete).
  static void success() => medium();

  /// Error or destructive actions (delete, fail).
  static void error() => heavy();

  /// Opening a bottom sheet or modal.
  static void sheetOpen() => light();

  /// Like / favourite toggle.
  static void like() => light();

  /// Long-press context menu trigger.
  static void longPress() => medium();
}
