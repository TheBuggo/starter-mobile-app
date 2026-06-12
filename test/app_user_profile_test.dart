import 'package:flutter_test/flutter_test.dart';
import 'package:starter_app/models/app_user_profile.dart';
import 'package:starter_app/models/theme_settings.dart';

void main() {
  test('copyWith keeps nullable profile fields when they are not changed', () {
    const profile = AppUserProfile(
      avatarUrl: 'https://example.com/me.png',
      city: 'New York',
      displayName: 'Alex',
      email: '',
      id: 'user-id',
      isAppOwner: false,
      phone: '+15555550100',
      telemetryEnabled: true,
      theme:
          ThemeSettings(name: 'Ocean', seedColor: 0xFF2563EB, darkMode: false),
    );

    final updated = profile.copyWith(
      theme: const ThemeSettings(
          name: 'Forest', seedColor: 0xFF0F766E, darkMode: false),
    );

    expect(updated.avatarUrl, profile.avatarUrl);
    expect(updated.city, profile.city);
    expect(updated.isAppOwner, isFalse);
    expect(updated.phone, profile.phone);
    expect(updated.telemetryEnabled, isTrue);
    expect(updated.theme.name, 'Forest');
  });

  test('copyWith can clear nullable profile fields', () {
    const profile = AppUserProfile(
      avatarUrl: 'https://example.com/me.png',
      city: 'New York',
      displayName: 'Alex',
      email: '',
      id: 'user-id',
      isAppOwner: false,
      phone: '+15555550100',
      telemetryEnabled: true,
      theme:
          ThemeSettings(name: 'Ocean', seedColor: 0xFF2563EB, darkMode: false),
    );

    final updated = profile.copyWith(avatarUrl: null, city: null);

    expect(updated.avatarUrl, isNull);
    expect(updated.city, isNull);
  });
}
