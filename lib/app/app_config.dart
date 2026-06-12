import 'package:flutter/foundation.dart';

class AppConfig {
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const inAppPurchasesEnabled = bool.fromEnvironment(
    'ENABLE_IN_APP_PURCHASES',
    defaultValue: false,
  );

  static String get supabaseUrl {
    return normalizeSupabaseUrlForPlatform(
      _supabaseUrl,
      defaultTargetPlatform,
    );
  }

  static bool get isSupabaseConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.host.isEmpty || supabaseAnonKey.length <= 20) {
      return false;
    }

    if (uri.scheme == 'https') {
      return true;
    }

    return uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  @visibleForTesting
  static String normalizeSupabaseUrlForPlatform(
    String url,
    TargetPlatform platform,
  ) {
    final uri = Uri.tryParse(url);
    if (uri == null || !_usesAndroidEmulatorLoopback(uri, platform)) {
      return url;
    }

    return uri.replace(host: '10.0.2.2').toString();
  }

  static bool _usesAndroidEmulatorLoopback(
    Uri uri,
    TargetPlatform platform,
  ) {
    return !kIsWeb &&
        platform == TargetPlatform.android &&
        uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1'}.contains(uri.host);
  }
}
