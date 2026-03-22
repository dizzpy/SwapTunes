import 'package:flutter/material.dart';

class SearchViewModel extends ChangeNotifier {
  final List<String> tabs = ['All', 'Users', 'Playlists', 'Creators', 'Albums'];
  String _activeTab = 'All';

  String get activeTab => _activeTab;

  final List<Map<String, String>> recentSearches = [
    {'title': 'Techno Summer Beat', 'subtitle': 'Dubstep Anthems'},
    {'title': 'Chillwave Vibes', 'subtitle': 'Funky Disco Nights'},
    {'title': 'Indie Pop Essentials', 'subtitle': 'Retro Synth Grooves'},
  ];

  final List<String> trendingTags = [
    '#SummerVibe',
    '#Collaboration',
    '#New',
    '#IndiePop',
    '#GlobalTop50',
    '#NatureLovers',
    '#FestivalFun',
  ];

  void setTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void removeRecentSearch(int index) {
    recentSearches.removeAt(index);
    notifyListeners();
  }

  void clearRecentSearches() {
    recentSearches.clear();
    notifyListeners();
  }
}
