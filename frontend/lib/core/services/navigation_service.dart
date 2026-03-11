import 'package:flutter/material.dart';

/// Global navigation service for navigating without BuildContext.
///
/// Useful for navigating from viewmodels or services.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Pushes a new route onto the navigation stack.
  static Future<dynamic> push(Widget page) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute<dynamic>(builder: (_) => page),
    );
  }

  /// Replaces the current route.
  static Future<dynamic> pushReplacement(Widget page) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute<dynamic>(builder: (_) => page),
    );
  }

  /// Pops the current route.
  static void pop() {
    navigatorKey.currentState!.pop();
  }

  /// Pops all routes and pushes a new one.
  static Future<dynamic> pushAndRemoveAll(Widget page) {
    return navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<dynamic>(builder: (_) => page),
      (_) => false,
    );
  }
}
