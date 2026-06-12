class ThemeSettings {
  const ThemeSettings({
    required this.name,
    required this.seedColor,
    required this.darkMode,
  });

  final String name;
  final int seedColor;
  final bool darkMode;

  static const defaultThemes = [
    ThemeSettings(name: 'Ocean', seedColor: 0xFF2563EB, darkMode: false),
    ThemeSettings(name: 'Forest', seedColor: 0xFF0F766E, darkMode: false),
    ThemeSettings(name: 'Rose', seedColor: 0xFFBE123C, darkMode: false),
    ThemeSettings(name: 'Violet', seedColor: 0xFF7C3AED, darkMode: false),
    ThemeSettings(name: 'Amber', seedColor: 0xFFB45309, darkMode: false),
    ThemeSettings(name: 'Slate', seedColor: 0xFF475569, darkMode: true),
  ];

  bool sameLookAs(ThemeSettings other) {
    return darkMode == other.darkMode &&
        name == other.name &&
        seedColor == other.seedColor;
  }

  factory ThemeSettings.fromProfileMap(Map<String, dynamic> map) {
    return ThemeSettings(
      darkMode: (map['theme_dark_mode'] as bool?) ?? false,
      name: (map['theme_name'] as String?) ?? defaultThemes.first.name,
      seedColor:
          (map['theme_seed_color'] as int?) ?? defaultThemes.first.seedColor,
    );
  }

  factory ThemeSettings.fromPresetMap(Map<String, dynamic> map) {
    return ThemeSettings(
      darkMode: (map['dark_mode'] as bool?) ?? false,
      name: (map['name'] as String?) ?? 'Custom',
      seedColor: (map['seed_color'] as int?) ?? defaultThemes.first.seedColor,
    );
  }

  Map<String, dynamic> toProfileMap() {
    return {
      'theme_dark_mode': darkMode,
      'theme_name': name,
      'theme_seed_color': seedColor,
    };
  }

  Map<String, dynamic> toPresetMap(String userId) {
    return {
      'dark_mode': darkMode,
      'name': name,
      'seed_color': seedColor,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
    };
  }

  ThemeSettings copyWith({
    bool? darkMode,
    String? name,
    int? seedColor,
  }) {
    return ThemeSettings(
      darkMode: darkMode ?? this.darkMode,
      name: name ?? this.name,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}
