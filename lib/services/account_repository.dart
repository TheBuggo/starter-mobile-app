import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_profile.dart';
import '../models/device_identity.dart';
import '../models/theme_settings.dart';
import '../models/user_entitlement.dart';

class AccountRepository {
  const AccountRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authState => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<User> ensureSignedIn({DeviceIdentity? deviceIdentity}) async {
    final existingUser = currentUser;
    if (existingUser != null) {
      await ensureProfile(existingUser, deviceIdentity: deviceIdentity);
      return existingUser;
    }

    final response = await _client.auth.signInAnonymously(
      data: {'account_source': 'device_account'},
    );

    final user = response.user ?? currentUser;
    if (user == null) {
      throw const AuthException('Could not create app account.');
    }

    await ensureProfile(user, deviceIdentity: deviceIdentity);
    return user;
  }

  Future<AppUserProfile> ensureProfile(
    User user, {
    DeviceIdentity? deviceIdentity,
    String? fallbackDisplayName,
  }) async {
    final existing =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    if (existing != null) {
      final profile = AppUserProfile.fromMap(existing);
      if (deviceIdentity == null ||
          profile.deviceIdentifierHash == deviceIdentity.identifierHash) {
        return profile;
      }

      return updateProfile(
        profile.copyWith(
          deviceIdentifierHash: deviceIdentity.identifierHash,
          deviceIdentifierKind: deviceIdentity.kind,
          devicePlatform: deviceIdentity.platform,
        ),
      );
    }

    final metadataName = user.userMetadata?['display_name'];
    final profile = AppUserProfile(
      displayName:
          fallbackDisplayName ?? (metadataName is String ? metadataName : ''),
      deviceIdentifierHash: deviceIdentity?.identifierHash,
      deviceIdentifierKind: deviceIdentity?.kind,
      devicePlatform: deviceIdentity?.platform,
      email: user.email ?? '',
      id: user.id,
      isAppOwner: false,
      phone: user.phone ?? '',
      telemetryEnabled: true,
      theme: ThemeSettings.defaultThemes.first,
    );

    await _client.from('profiles').upsert(profile.toMap());
    return profile;
  }

  Future<AppUserProfile> updateProfile(AppUserProfile profile) async {
    final updated = await _client
        .from('profiles')
        .update(profile.toUpdateMap())
        .eq('id', profile.id)
        .select()
        .single();

    return AppUserProfile.fromMap(updated);
  }

  Future<List<UserEntitlement>> loadEntitlements(String userId) async {
    final rows = await _client
        .from('user_entitlements')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows.map((row) => UserEntitlement.fromMap(row)).toList();
  }

  Future<List<ThemeSettings>> loadThemePresets(String userId) async {
    final rows = await _client
        .from('theme_presets')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows.map((row) => ThemeSettings.fromPresetMap(row)).toList();
  }

  Future<void> saveThemePreset(ThemeSettings theme) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    await _client.from('theme_presets').upsert(
          theme.toPresetMap(user.id),
          onConflict: 'user_id,name',
        );
  }
}
