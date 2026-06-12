import 'theme_settings.dart';

const _unset = Object();

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAppOwner,
    required this.phone,
    required this.telemetryEnabled,
    required this.theme,
    this.avatarUrl,
    this.city,
    this.deviceIdentifierHash,
    this.deviceIdentifierKind,
    this.devicePlatform,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isAppOwner;
  final String phone;
  final bool telemetryEnabled;
  final String? avatarUrl;
  final String? city;
  final String? deviceIdentifierHash;
  final String? deviceIdentifierKind;
  final String? devicePlatform;
  final ThemeSettings theme;

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String?,
      deviceIdentifierHash: map['device_identifier_hash'] as String?,
      deviceIdentifierKind: map['device_identifier_kind'] as String?,
      devicePlatform: map['device_platform'] as String?,
      displayName: (map['display_name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      id: map['id'] as String,
      isAppOwner: (map['is_app_owner'] as bool?) ?? false,
      phone: (map['phone'] as String?) ?? '',
      telemetryEnabled: (map['telemetry_enabled'] as bool?) ?? true,
      theme: ThemeSettings.fromProfileMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avatar_url': avatarUrl,
      'city': city,
      'device_identifier_hash': deviceIdentifierHash,
      'device_identifier_kind': deviceIdentifierKind,
      'device_platform': devicePlatform,
      'display_name': displayName,
      'email': email,
      'id': id,
      'phone': phone,
      'telemetry_enabled': telemetryEnabled,
      ...theme.toProfileMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'avatar_url': avatarUrl,
      'city': city,
      'device_identifier_hash': deviceIdentifierHash,
      'device_identifier_kind': deviceIdentifierKind,
      'device_platform': devicePlatform,
      'display_name': displayName,
      'telemetry_enabled': telemetryEnabled,
      ...theme.toProfileMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  AppUserProfile copyWith({
    Object? avatarUrl = _unset,
    Object? city = _unset,
    Object? deviceIdentifierHash = _unset,
    Object? deviceIdentifierKind = _unset,
    Object? devicePlatform = _unset,
    String? displayName,
    bool? isAppOwner,
    bool? telemetryEnabled,
    ThemeSettings? theme,
  }) {
    return AppUserProfile(
      avatarUrl:
          identical(avatarUrl, _unset) ? this.avatarUrl : avatarUrl as String?,
      city: identical(city, _unset) ? this.city : city as String?,
      deviceIdentifierHash: identical(deviceIdentifierHash, _unset)
          ? this.deviceIdentifierHash
          : deviceIdentifierHash as String?,
      deviceIdentifierKind: identical(deviceIdentifierKind, _unset)
          ? this.deviceIdentifierKind
          : deviceIdentifierKind as String?,
      devicePlatform: identical(devicePlatform, _unset)
          ? this.devicePlatform
          : devicePlatform as String?,
      displayName: displayName ?? this.displayName,
      email: email,
      id: id,
      isAppOwner: isAppOwner ?? this.isAppOwner,
      phone: phone,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      theme: theme ?? this.theme,
    );
  }
}
