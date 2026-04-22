import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swaptune/features/profile/data/models/full_profile_model.dart';
import 'package:swaptune/features/profile/presentation/widgets/creator_info_section.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('renders creator role, location and first link', (tester) async {
    const creator = CreatorProfile(
      roleTitle: 'Producer',
      location: 'Colombo',
      specializations: ['Rock'],
      soundcloudUrl: 'https://soundcloud.com/test',
      youtubeUrl: 'https://youtube.com/test',
    );

    await tester.pumpWidget(_wrap(const CreatorInfoSection(creator: creator)));

    expect(find.text('Producer'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('https://soundcloud.com/test'), findsOneWidget);
    expect(find.text('See More'), findsOneWidget);
  });

  testWidgets('opens links bottom sheet when See More is tapped', (
    tester,
  ) async {
    const creator = CreatorProfile(
      roleTitle: 'Producer',
      location: 'Colombo',
      specializations: ['Rock'],
      soundcloudUrl: 'https://soundcloud.com/test',
      youtubeUrl: 'https://youtube.com/test',
    );

    await tester.pumpWidget(_wrap(const CreatorInfoSection(creator: creator)));

    await tester.tap(find.text('See More'));
    await tester.pumpAndSettle();

    expect(find.text('SoundCloud'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
  });
}
