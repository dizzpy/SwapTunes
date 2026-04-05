import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swaptune/features/profile/presentation/widgets/profile_header.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildSubject({
  String? coverUrl,
  String? avatarUrl,
  bool isCreatorMode = false,
  VoidCallback? onAvatarTap,
  VoidCallback? onCoverTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProfileCoverHeader(
        coverUrl: coverUrl,
        avatarUrl: avatarUrl,
        isCreatorMode: isCreatorMode,
        onAvatarTap: onAvatarTap,
        onCoverTap: onCoverTap,
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders without throwing — no avatar, no cover', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.byType(ProfileCoverHeader), findsOneWidget);
  });

  testWidgets('renders in listener mode (centered avatar)', (tester) async {
    await tester.pumpWidget(_buildSubject(isCreatorMode: false));
    await tester.pump();
    expect(find.byType(ProfileCoverHeader), findsOneWidget);
  });

  testWidgets('renders in creator mode (left-aligned avatar)', (tester) async {
    await tester.pumpWidget(_buildSubject(isCreatorMode: true));
    await tester.pump();
    expect(find.byType(ProfileCoverHeader), findsOneWidget);
  });

  testWidgets('tapping avatar calls onAvatarTap callback', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _buildSubject(onAvatarTap: () => tapped = true),
    );
    await tester.pump();

    // Avatar is Positioned(bottom: -60) inside the Stack (160px tall).
    // Its top is at ~100px from the Stack's top, within Stack bounds.
    // Tap the upper portion of the avatar GestureDetector to stay inside
    // the Stack's hit-test region.
    final avatarGD = find.byType(GestureDetector).first;
    final topLeft = tester.getTopLeft(avatarGD);
    await tester.tapAt(Offset(topLeft.dx + 60, topLeft.dy + 20));
    await tester.pump();

    expect(tapped, true);
  });

  testWidgets('tapping cover calls onCoverTap callback', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _buildSubject(onCoverTap: () => tapped = true),
    );
    await tester.pump();

    final coverFinder = find.byType(GestureDetector).first;
    await tester.tap(coverFinder);
    await tester.pump();

    expect(tapped, true);
  });

  testWidgets('no callbacks — no GestureDetectors rendered', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.byType(GestureDetector), findsNothing);
  });
}
