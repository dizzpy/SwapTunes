import 'package:flutter/material.dart';

class DiscoverViewModel extends ChangeNotifier {
  // Mock data for the UI to demonstrate MVVM architecture
  final List<String> genres = [
    'Hip-Hop',
    'Jazz',
    'Rock',
    'Classical',
    'Reggae',
  ];

  final List<Map<String, String>> futurePlaylists = [
    {
      'title': 'Pillow Talk',
      'subtitle': 'Chill melodic dubstep for cozy nights',
      'image': 'https://picsum.photos/seed/pillow/200/200',
    },
    {
      'title': 'Sleepwalker',
      'subtitle': 'Dreamy melodies with haunting vibes',
      'image': 'https://picsum.photos/seed/sleep/200/200',
    },
    {
      'title': 'Retro Dreams',
      'subtitle': 'Synthwave beats to relax',
      'image': 'https://picsum.photos/seed/retro/200/200',
    },
  ];

  final List<Map<String, String>> suggestedUsers = [
    {
      'name': 'Skrillex',
      'subtitle': 'Dubstep Anthems',
      'avatar': 'https://picsum.photos/seed/skrillex/100/100',
    },
    {
      'name': 'Tiësto',
      'subtitle': 'Dance & EDM',
      'avatar': 'https://picsum.photos/seed/tiesto/100/100',
    },
  ];
}
