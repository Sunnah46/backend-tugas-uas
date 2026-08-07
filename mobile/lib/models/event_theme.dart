class EventTheme {
  final String asset;
  final String label;

  const EventTheme({required this.asset, required this.label});

  static const List<EventTheme> all = [
    EventTheme(asset: 'assets/images/event_themes/tema_1.png', label: 'Navy'),
    EventTheme(asset: 'assets/images/event_themes/tema_2.png', label: 'Gold'),
    EventTheme(asset: 'assets/images/event_themes/tema_3.png', label: 'Teal'),
    EventTheme(asset: 'assets/images/event_themes/tema_4.png', label: 'Royal'),
    EventTheme(asset: 'assets/images/event_themes/tema_5.png', label: 'Maroon'),
    EventTheme(asset: 'assets/images/event_themes/tema_6.png', label: 'Forest'),
    EventTheme(asset: 'assets/images/event_themes/tema_7.png', label: 'Sunset'),
    EventTheme(asset: 'assets/images/event_themes/tema_8.png', label: 'Ocean'),
  ];

  static EventTheme? fromAsset(String? asset) {
    if (asset == null || asset.isEmpty) return null;
    for (final theme in all) {
      if (theme.asset == asset) return theme;
    }
    return null;
  }
}
